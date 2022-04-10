#include "nvme_cmd.h"
#include "pcie_req.h"
#include "pcie_data_buf.h"
#include "nvme_admin_cmd.h"


u64 admin_sq_base_addr;
u64 admin_cq_base_addr;
u32 admin_sq_size;
u32 admin_cq_size;

u32 admin_sq_tail_fetched;
u32 admin_sq_tail_done;
u32 admin_cq_tail_now;

u32 admin_sq_tail;

u32 num_of_queues;
u32 vwce; //Volatile Write Cache Enable from set features Feature Identifier 06h

u32 admin_phase_tag;

u64 io1_sq_base_addr;
u64 io1_cq_base_addr;
u32 io1_sq_size;
u32 io1_cq_size;
u32 io1_irq_vector = 0;

extern u32 msi_flag[8];


static void exec_admin_cmd(u32 sq_id);
static void post_admin_completion(u32 sq_id);

void reset_local_admin_reg()
{
	admin_sq_tail_fetched = 0;
	admin_sq_tail_done = 0;
	admin_cq_tail_now = 0;
	
	admin_phase_tag = 0x10000;
	vwce = 0;
}

void update_db_admin_reg()
{
	admin_sq_tail = read_pl_reg(0x1000);
	
	admin_sq_base_addr = (u64)read_pl_reg(0x28) | ((u64)read_pl_reg(0x2C) << 32);
	admin_cq_base_addr = (u64)read_pl_reg(0x30) | ((u64)read_pl_reg(0x34) << 32);
	admin_sq_size = (read_pl_reg(0x24) & 0xfff) + 1;
	admin_cq_size = ((read_pl_reg(0x24) >> 16) & 0xfff) + 1;
}

void read_admin_command()
{
	NVME_REQ_BUF_ELEMENT *req_element = NVME_ADMIN_REQ_BUF_ADDR;
	u32 sq_id;

	for(sq_id=admin_sq_tail_fetched;sq_id!=admin_sq_tail;)
	{
		u32 allocated_buf = allocate_data_buf(0x40);
		
		if(allocated_buf == NIL)
			break;

		u32 checkpoint = send_pcie_read_tlp(allocated_buf, admin_sq_base_addr+sq_id*0x40, 0x10);
		
		//xil_printf("admin_sq_tail_fetched %x %x %x\r\n",sq_id,allocated_buf,checkpoint);
		
		req_element[sq_id].exec_state = 0;
		req_element[sq_id].pcie_rw = 0;
		req_element[sq_id].checkpoint_start = checkpoint;
		req_element[sq_id].checkpoint_end = checkpoint;
		req_element[sq_id].cmd_addr = allocated_buf;
		req_element[sq_id].prp_addr = 0;
		req_element[sq_id].exec_addr = 0;
		
		sq_id++;
		if(sq_id == admin_sq_size)
			sq_id = 0;
	}

	admin_sq_tail_fetched = sq_id;
}

void update_admin_req_status()
{
	//xil_printf("update_admin_req_status\r\n");
	
	NVME_REQ_BUF_ELEMENT *req_element = NVME_ADMIN_REQ_BUF_ADDR;
	u32 sq_id;	
	
	for(sq_id=admin_sq_tail_done; sq_id != admin_sq_tail_fetched; )
	{	
		if(req_element[sq_id].exec_state < 4)
			break;
		
		invalid_data_buf(req_element[sq_id].cmd_addr);
		if(req_element[sq_id].prp_addr)
			invalid_data_buf(req_element[sq_id].prp_addr);
		if(req_element[sq_id].exec_addr)
			invalid_data_buf(req_element[sq_id].exec_addr);
		
		sq_id++;
		if(sq_id == admin_sq_size)
			sq_id = 0;
		
		//xil_printf("admin_sq_tail_done: %x\r\n",sq_id);
		if(sq_id == admin_sq_tail_fetched)
			msi_flag[0] = 1;
			//send_msi(0);
	}
	
	admin_sq_tail_done = sq_id;
	
	for( ; sq_id != admin_sq_tail_fetched; )
	{	
		if( req_element[sq_id].pcie_rw )
		{
			u32 reg40c = read_pl_reg(0x40c);
			u16 req_pointer_now = reg40c & 0xffff;
			u16 req_overlap_now = reg40c >> 16;
					
			if(req_element[sq_id].req_overlap_target >= req_element[sq_id].req_overlap_origin)
			{
				if(req_overlap_now >= req_element[sq_id].req_overlap_origin && req_overlap_now < req_element[sq_id].req_overlap_target)
				{
					goto for_end;
				}
				else if(req_overlap_now == req_element[sq_id].req_overlap_target)
				{
					if(req_pointer_now < req_element[sq_id].req_pointer_target)
						goto for_end;
				}
			}
			else
			{
				if(req_overlap_now >= req_element[sq_id].req_overlap_origin || req_overlap_now < req_element[sq_id].req_overlap_target)
				{
					goto for_end;
				}
				else if(req_overlap_now == req_element[sq_id].req_overlap_target)
				{
					if(req_pointer_now < req_element[sq_id].req_pointer_target)
						goto for_end;
				}
			}
		}
		else
		{
			u32 check_flag = 0;
			volatile PCIE_REQ_BUF_ELEMENT *check_point = req_element[sq_id].checkpoint_start;
			
			while(1)
			{
				if( check_point->pcie_req_len != NIL )
				{
					check_flag = 1;
					break;
				}
				
				if( (u32)check_point == req_element[sq_id].checkpoint_end )
				{
					break;
				}
				
				check_point = (u32)check_point + sizeof(PCIE_REQ_BUF_ELEMENT);
				if((u32)check_point >= PCIE_READ_REQ_BUF_ADDR + PCIE_REQ_LEN)
					check_point = PCIE_READ_REQ_BUF_ADDR;
			}
			
			if(check_flag)
				goto for_end;
		}
		
	
		if(req_element[sq_id].exec_state == 0)
		{
			read_prp_entry(NVME_ADMIN_REQ_BUF_ADDR,sq_id);
		}
		
		if(req_element[sq_id].exec_state == 1)
		{
			exec_admin_cmd(sq_id);
		}
		
		if(req_element[sq_id].exec_state == 2)
		{
			post_admin_completion(sq_id);
		}
		
		if(req_element[sq_id].exec_state < 5)
		{
			/*xil_printf("update_admin_req_status: %x %x:",sq_id, req_element[sq_id].exec_state);
			u32 *cmd_addr = req_element[sq_id].cmd_addr;

			for(u32 i=0; i<0x10; i++)
				xil_printf(" %x",cmd_addr[i]);
			xil_printf("\r\n");*/
			
			req_element[sq_id].exec_state++;
		}
		
		
	for_end:
	
		sq_id++;
		if(sq_id == admin_sq_size)
			sq_id = 0;
	}
}

static void exec_admin_cmd(u32 sq_id)
{
	NVME_REQ_BUF_ELEMENT *req_element = NVME_ADMIN_REQ_BUF_ADDR;
	u32 *cmd_addr = req_element[sq_id].cmd_addr;
	
	u32 opc = cmd_addr[0] & 0xff;
	
	xil_printf("exec_admin_cmd: %x\r\n",opc);
	/*for(u32 i=0; i<0x10; i++)
		xil_printf(" %x",cmd_addr[i]);
	xil_printf("\r\n");*/

	if(opc == 0x6){
		unsigned int prp[2];
		int prpLen;
		
		u32 allocated_buf = allocate_data_buf(0x1000);
		
		if(allocated_buf == NIL)
			return;
		
		req_element[sq_id].exec_addr = allocated_buf;

		if(cmd_addr[10] & 0x1)
			identify_controller(allocated_buf);
		else
			identify_namespace(allocated_buf);

		prp[0] = cmd_addr[6];
		prp[1] = cmd_addr[7];
		prpLen = 0x1000 - (prp[0] & 0xFFF);
		
		req_element[sq_id].pcie_rw = 1;
		req_element[sq_id].checkpoint_start = read_pl_reg(0x40c); //req_overlap_origin+req_pointer_origin

		while(1)
		{
			//req_overlap_target+req_pointer_target
			req_element[sq_id].checkpoint_end = send_pcie_write_tlp(allocated_buf,((u64)prp[0] | ((u64)prp[1]) << 32), prpLen/4);

			if(prpLen == 0x1000)
				break;

			prp[0] = cmd_addr[8];
			prp[1] = cmd_addr[9];
			
			//req_overlap_target+req_pointer_target
			req_element[sq_id].checkpoint_end = send_pcie_write_tlp(allocated_buf+prpLen,((u64)prp[0] | ((u64)prp[1]) << 32), (0x1000 - prpLen)/4);

			break;
		}

	} else if(opc == 0x1){
		if((cmd_addr[10] & 0xffff) == 0x1){
			io1_sq_base_addr = ((u64)cmd_addr[7] << 32) | (u64) cmd_addr[6];
			io1_sq_size = (cmd_addr[10] >> 16)+1;
		}
		//xil_printf("io sq %d created\r\n",cmd_addr[10] & 0xffff);
		req_element[sq_id].exec_state = 2;
	} else if(opc == 0x5){
		if((cmd_addr[10] & 0xffff) == 0x1){
			if(cmd_addr[11] & 0x2)
				io1_irq_vector = (cmd_addr[11] >> 16);
			else
				io1_irq_vector = 0xffffffff;
			io1_cq_base_addr = ((u64)cmd_addr[7] << 32) | (u64) cmd_addr[6];
			io1_cq_size = (cmd_addr[10] >> 16)+1;
		}
		//xil_printf("io cq %d created\r\n",cmd_addr[10] & 0xffff);
		req_element[sq_id].exec_state = 2;
	} else { //get log page
		req_element[sq_id].exec_state = 2;
	} 
}

static void post_admin_completion(u32 sq_id)
{
	NVME_REQ_BUF_ELEMENT *req_element = NVME_ADMIN_REQ_BUF_ADDR;
	u32 *cmd_addr = req_element[sq_id].cmd_addr;
	u32 opc = cmd_addr[0] & 0xff;
	
	//xil_printf("post_admin_completion: %x %x\r\n",sq_id,opc);
	
	u32 next_sq_id = sq_id + 1;
	if(next_sq_id == admin_sq_size)
		next_sq_id = 0;

	if( opc != 0xc ){ // != Asynchronous Event Request command

		cmd_addr[3] = (0 << 17) | admin_phase_tag | (cmd_addr[0] >> 16);
		cmd_addr[2] = (0 << 16) | (next_sq_id & 0xffff);
		cmd_addr[1] = 0;

		if( opc == 0x9 ) { //set features
			u32 fid = cmd_addr[10] & 0xff; //Volatile write cache
			if(fid == 0x6){
				cmd_addr[0] = 0;
				vwce = cmd_addr[11] & 0x1;
			} else if( (cmd_addr[10]&0xff) == 0x7 ) { //Number of Queues
				cmd_addr[0] = cmd_addr[11];
				num_of_queues = cmd_addr[11];
			}
		} else if( opc == 0xA ) { //get features
			u32 fid = cmd_addr[10] & 0xff; //Volatile write cache
			if(fid == 0x6){ //Volatile write cache
				cmd_addr[0] = vwce;
			} else if( (cmd_addr[10]&0xff) == 0x7 ) { //Number of Queues
				cmd_addr[0] = num_of_queues;
			}
		} else if( opc == 0x9 ) //Get Log Page
			cmd_addr[0] = 0x9; //Invalid Log Page
		else
			cmd_addr[0] = 0;
		
		//xil_printf("t%d: %x %x %x %x\r\n",admin_cq_tail_now,cmd_addr[0],cmd_addr[1],cmd_addr[2],cmd_addr[3]);
		
		req_element[sq_id].pcie_rw = 1;
		req_element[sq_id].checkpoint_start = read_pl_reg(0x40c); //req_overlap_origin+req_pointer_origin
		req_element[sq_id].checkpoint_end = send_pcie_write_tlp(cmd_addr, admin_cq_base_addr+admin_cq_tail_now*0x10, 4);
		
		admin_cq_tail_now++;
		if(admin_cq_tail_now == admin_cq_size)
		{
			admin_cq_tail_now = 0;
			admin_phase_tag ^= 0x10000;
		}
	}
	else
		req_element[sq_id].exec_state = 3;
}