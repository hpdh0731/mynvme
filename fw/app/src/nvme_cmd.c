#include "nvme_cmd.h"
#include "pcie_req.h"
#include "pcie_data_buf.h"
#include "nvme_admin_cmd.h"
#include "nvme_io_cmd.h"

u32 msi_flag[8];

extern u32 io1_sq_tail_fetched;
extern u32 io1_sq_tail_done;
extern u32 admin_sq_tail_fetched;
extern u32 admin_sq_tail_done;


u32 reset_local_db_reg()
{
	reset_local_admin_reg();
	reset_local_io_reg();
	
	init_data_buf();
}

u32 update_db_reg(u32 ctrl_state)
{
	static u32 cc_reg_prev = 0;
	
	wait_pcie_reset();
	
	update_db_admin_reg();
	update_db_io_reg();

	u32 cc_reg = read_pl_reg(0x14);
	
	u32 cc_reg_change = cc_reg ^ cc_reg_prev;

	if(cc_reg_change & 0x1) {
		ctrl_state = (cc_reg & 0x1) ? 1 : 4; //booting : reset
	}
	
	if(cc_reg_change & 0xC000) {
		ctrl_state = (cc_reg & 0xC000) ? 3 : ctrl_state; //shutdown
	}
	
	
	cc_reg_prev = cc_reg;

	return ctrl_state;
}

void read_prp_entry(NVME_REQ_BUF_ELEMENT *req_buf, u32 sq_id)
{
	NVME_REQ_BUF_ELEMENT *req_element = req_buf;
	u32 *cmd_addr = req_element[sq_id].cmd_addr;
	
	u32 prp1_offset = cmd_addr[6] & LBA_UNIT_MASK;
	u32 prp_len = prp1_offset != 0 ? (cmd_addr[12] & 0xffff) +2 : (cmd_addr[12] & 0xffff) +1;
	
	if(prp_len <= 2)
	{
		req_element[sq_id].exec_state = 1;
		return;
	}
	
	//xil_printf("read_prp_entry: %x\r\n",prp_len);
	
	prp_len--;

	u32 allocated_buf = allocate_data_buf(prp_len*8);
		
	if(allocated_buf == NIL)
		return;
	
	req_element[sq_id].prp_addr = allocated_buf;
	
	u64 prp2 = (u64)cmd_addr[8] | ((u64)cmd_addr[9] << 32);
	u32 prp2_offset = prp2 & (PCIE_RCB-1);
	
	if(prp2_offset+prp_len*8 <= PCIE_RCB) //unit: byte
	{
		req_element[sq_id].checkpoint_start = send_pcie_read_tlp(allocated_buf, prp2, prp_len*2); //unit: dword
		req_element[sq_id].checkpoint_end = req_element[sq_id].checkpoint_start;
	}
	else
	{
		u32 prp_size = (PCIE_RCB - prp2_offset)/4; //unit: dword
		req_element[sq_id].checkpoint_start = send_pcie_read_tlp(allocated_buf, prp2, prp_size);
		allocated_buf += prp_size*4;
		prp2 += prp_size*4;
		req_element[sq_id].checkpoint_end = send_pcie_read_tlp(allocated_buf, prp2, prp_len*2-prp_size);
	}
}


void handle_nvme_req()
{
	read_admin_command();
	read_io_command();

	update_admin_req_status();
	update_io_req_status();
	
	release_data_buf();
		
	if(msi_flag[0] & !(read_pl_reg(0x10) & 0x1))
	{
		usleep(20);
		if(!(read_pl_reg(0x10) & 0x1))
		{
			send_msi(0);
			msi_flag[0] = 0;
		}
	}
}
