#include "nvme_cmd.h"
#include "pcie_req.h"
#include "pcie_data_buf.h"
#include "nvme_io_cmd.h"
#include "lb2pb.h"


extern u64 io1_sq_base_addr;
extern u64 io1_cq_base_addr;
extern u32 io1_sq_size;
extern u32 io1_cq_size;
extern u32 io1_irq_vector;
extern u32 msi_flag[8];

u32 io1_sq_tail_fetched;
u32 io1_sq_tail_done;
u32 io1_cq_tail_now;
u32 io1_sq_tail;
u32 io1_phase_tag;


static void exec_io_cmd(u32 sq_id);
static void post_io_completion(u32 sq_id);

void reset_local_io_reg()
{
	io1_sq_tail_fetched = 0;
	io1_sq_tail_done = 0;
	io1_cq_tail_now = 0;
	
	io1_phase_tag = 0x10000;
}

void update_db_io_reg()
{
	io1_sq_tail = read_pl_reg(0x1008);
}

void read_io_command()
{
	NVME_REQ_BUF_ELEMENT *req_element = NVME_IO1_REQ_BUF_ADDR;
	u32 sq_id;

	for(sq_id=io1_sq_tail_fetched;sq_id!=io1_sq_tail;)
	{
		//xil_printf("io_fetched=%x\r\n",sq_id);
		
		u32 allocated_buf = allocate_data_buf(0x40);
		
		if(allocated_buf == NIL)
			break;

		u32 checkpoint = send_pcie_read_tlp(allocated_buf, io1_sq_base_addr+sq_id*0x40, 0x10);
		
		//xil_printf("io_sq_tail_fetched %x %x %x\r\n",sq_id,allocated_buf,checkpoint);
		
		req_element[sq_id].exec_state = 0;
		req_element[sq_id].pcie_rw = 0;
		req_element[sq_id].checkpoint_start = checkpoint;
		req_element[sq_id].checkpoint_end = checkpoint;
		req_element[sq_id].cmd_addr = allocated_buf;
		req_element[sq_id].prp_addr = 0;
		req_element[sq_id].exec_addr = 0;
		req_element[sq_id].timeout_cnt = read_pl_reg(0x600);
		
		sq_id++;
		if(sq_id == io1_sq_size)
			sq_id = 0;
	}

	io1_sq_tail_fetched = sq_id;
}

void update_io_req_status()
{
	NVME_REQ_BUF_ELEMENT *req_element = NVME_IO1_REQ_BUF_ADDR;
	u32 sq_id;
	
	//static u32 error_count;

	/*if(read_pl_reg(0x608) != error_count)
	{
		error_count = read_pl_reg(0x608);
		xil_printf("error_count=%d\r\n",error_count);
	}*/
	
	for(sq_id=io1_sq_tail_done; sq_id != io1_sq_tail_fetched; )
	{	
		if(req_element[sq_id].exec_state < 4)
			break;
		
		invalid_data_buf(req_element[sq_id].cmd_addr);
		if(req_element[sq_id].prp_addr)
			invalid_data_buf(req_element[sq_id].prp_addr);
		if(req_element[sq_id].exec_addr)
			invalid_data_buf(req_element[sq_id].exec_addr);
		
		sq_id++;
		if(sq_id == io1_sq_size)
			sq_id = 0;
		
		//xil_printf("io_done: %x\r\n",sq_id);
		
		if(io1_irq_vector != 0xffffffff && sq_id == io1_sq_tail_fetched)
			msi_flag[io1_irq_vector] = 1;
			//send_msi(io1_irq_vector);
	}
	
	io1_sq_tail_done = sq_id;
	

	for( ; sq_id != io1_sq_tail_fetched; )
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
			volatile PCIE_REQ_BUF_ELEMENT* check_point = req_element[sq_id].checkpoint_start;

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
			{
				/*if(read_pl_reg(0x600) - req_element[sq_id].timeout_cnt > 250000000)
				{
					volatile PCIE_REQ_BUF_ELEMENT *old_req = check_point;
					PCIE_REQ_BUF_ELEMENT* old_req_end = req_element[sq_id].checkpoint_end;
					xil_printf("cpld loss timeout\r\n");
					write_pl_reg(0x900,0x0);
					req_element[sq_id].checkpoint_start = send_pcie_read_tlp(old_req->pcie_data_addr, old_req->pcie_req_addr, old_req->pcie_req_len);
					req_element[sq_id].checkpoint_end = req_element[sq_id].checkpoint_start;
					
					xil_printf("req pointer: %x %x %x\r\n",req_element[sq_id].checkpoint_start,old_req,req_element[sq_id].checkpoint_end);
					xil_printf("%x %x %x\r\n",old_req->pcie_data_addr, old_req->pcie_req_addr, old_req->pcie_req_len);
					
					while(1)
					{
						if( old_req == old_req_end )
						{
							break;
						}
						
						old_req = (u32)old_req + sizeof(PCIE_REQ_BUF_ELEMENT);
						if((u32)old_req >= PCIE_READ_REQ_BUF_ADDR + PCIE_REQ_LEN)
							old_req = PCIE_READ_REQ_BUF_ADDR;
						
						if( old_req->pcie_req_len != NIL )
						{
							req_element[sq_id].checkpoint_end = send_pcie_read_tlp(old_req->pcie_data_addr, old_req->pcie_req_addr, old_req->pcie_req_len);
							xil_printf("%x %x %x\r\n",old_req->pcie_data_addr, old_req->pcie_req_addr, old_req->pcie_req_len);
						}
					}	
					req_element[sq_id].timeout_cnt = read_pl_reg(0x600);
							
				}*/
				goto for_end;
			}
		}
		
		
		if(req_element[sq_id].exec_state == 0)
		{
			read_prp_entry(NVME_IO1_REQ_BUF_ADDR,sq_id);
		}
		
		if(req_element[sq_id].exec_state == 1)
		{
			exec_io_cmd(sq_id);
		}
		
		if(req_element[sq_id].exec_state == 2)
		{
			post_io_completion(sq_id);
		}
		
		req_element[sq_id].timeout_cnt = read_pl_reg(0x600);
		
		if(req_element[sq_id].exec_state < 5)
		{
			/*xil_printf("update_io_req_status: %x %x:",sq_id,req_element[sq_id].exec_state);

			u32 *cmd_addr = req_element[sq_id].cmd_addr;
			for(u32 i=0; i<0x10; i++)
				xil_printf(" %x",cmd_addr[i]);
			xil_printf("\r\n");*/
		
			req_element[sq_id].exec_state++;
		}
		
	for_end:

		sq_id++;
		if(sq_id == io1_sq_size)
			sq_id = 0;
	}
}

static void exec_io_cmd(u32 sq_id)
{
	NVME_REQ_BUF_ELEMENT *req_element = NVME_IO1_REQ_BUF_ADDR;
	u32 *cmd_addr = req_element[sq_id].cmd_addr;
	
	u32 opc = cmd_addr[0] & 0xff;
	
	/*xil_printf("exec_io_cmd:");
	
	for(u32 i=0; i<0x10; i++)
		xil_printf(" %x",cmd_addr[i]);
	xil_printf("\r\n");*/
	
	
	if(opc == 0x1 || opc == 0x2) //write or read
	{
		if(opc == 0x1)
			xil_printf("W");
		else
			xil_printf("R");
		
		const u32 prp1_offset = cmd_addr[6] & LBA_UNIT_MASK;
		const u64 slba = ((u64)cmd_addr[10] | ((u64)cmd_addr[11] << 32));

		u32 prp_len = prp1_offset != 0 ? (cmd_addr[12] & 0xffff) +2 : (cmd_addr[12] & 0xffff) +1;

		volatile u64 *prp_arr = DUMMY_BRAM_ADDR;

		prp_arr[0] = (u64)cmd_addr[6] | ((u64)cmd_addr[7] << 32);

		if(prp_len > 2)
		{
			volatile u64 *prp_addr = req_element[sq_id].prp_addr;
			
			for(u32 k=1; k<prp_len; k++)
				prp_arr[k] = prp_addr[k-1];
		}
		else if(prp_len == 2)
			prp_arr[1] = (u64)cmd_addr[8] | ((u64)cmd_addr[9] << 32);

		u64 mem_addr = slba*LBA_UNIT_SIZE;
		const u64 mem_addr_end = ((cmd_addr[12] & 0xffff) +1)*LBA_UNIT_SIZE +mem_addr; //from NLB

		u32 prp_index = 0;
		u32 tlp_len = prp1_offset;
		u32 block_offset;
		u64 lba = slba;
		u32 pba = 0xffffffff;
		u32 prp_offset = 0;
		u32 tlp_len_arr_index;

		u32 tlp_len_arr[3];
		u32 tlp_len_arr_len;

		if(opc == 0x1) //write
			tlp_len_arr[1] = (0x80 - (prp1_offset & 0x7f)) & 0x7f;
		else //read
			tlp_len_arr[1] = (PCIE_RCB - (prp1_offset & (PCIE_RCB-1))) & (PCIE_RCB-1);
		tlp_len_arr[2] = prp1_offset & LBA_UNIT_MASK;
		tlp_len_arr[0] = LBA_UNIT_SIZE - tlp_len_arr[1] - tlp_len_arr[2];

		if(tlp_len_arr[2] == 0x0)
		{
			tlp_len_arr_len = 1;
			tlp_len_arr_index = 0;
		}
		else if(tlp_len_arr[1] == 0x0)
		{
			tlp_len_arr_len = 2;
			tlp_len_arr_index = 0;
			tlp_len_arr[1] = tlp_len_arr[2];
		}
		else if(tlp_len_arr[0] == 0x0)
		{
			tlp_len_arr_len = 2;
			tlp_len_arr_index = 0;
			tlp_len_arr[0] = tlp_len_arr[1];
			tlp_len_arr[1] = tlp_len_arr[2];
		}
		else
		{
			tlp_len_arr_len = 3;
			tlp_len_arr_index = 1;
		}
		
		if(opc == 0x1) //write
		{
			req_element[sq_id].pcie_rw = 0;
			req_element[sq_id].checkpoint_start = 0;
		}
		else //read
		{
			req_element[sq_id].pcie_rw = 1;
			req_element[sq_id].checkpoint_start = read_pl_reg(0x40c);
		}


		while(mem_addr < mem_addr_end)
		{
			block_offset = mem_addr & SLICE_BLOCK_MASK;

			if(tlp_len_arr_index == tlp_len_arr_len) {
				prp_index++;
				prp_offset = 0;
				
				if(block_offset > SLICE_BLOCK_SIZE-LBA_UNIT_SIZE)
				{
					tlp_len = SLICE_BLOCK_SIZE - block_offset;
					
					if(tlp_len_arr_len > 1)
						tlp_len_arr_index = tlp_len_arr_len-2;
					else
						tlp_len_arr_index = tlp_len_arr_len;
				}
				else
				{
					tlp_len = LBA_UNIT_SIZE;
				}

			} else {
				tlp_len = tlp_len_arr[tlp_len_arr_index];
				
				if(tlp_len_arr_index == 0)
					tlp_len_arr_index = tlp_len_arr_len;
				else
					tlp_len_arr_index--;
			}

			if(mem_addr + (u64)tlp_len > mem_addr_end)
				tlp_len = mem_addr_end - mem_addr;


			if(pba == 0xffffffff || block_offset == 0)
			{
				pba = get_pba_from_table(mem_addr/LBA_UNIT_SIZE);
				//xil_printf("update pba\r\n");
				

				if(get_lba_status() & 0x1)
				{
					//write dirty data to server
					//get_dirty_lsba()
					//xil_printf("write dirty data to server\r\n");
				}
				if(get_lba_status() & 0x2)
				{
					//read block data(pba) from server
					//xil_printf("read block data from server\r\n");

					for(int i=0;i<SLICE_BLOCK_SIZE;i+=4)
						*((volatile int *)(0x40000000+LBA_UNIT_SIZE*pba+i)) = 0xFFFFFFFF;
				}
			}
			
			//xil_printf("%x %x %x %x\r\n",read_pl_reg(0x510),read_pl_reg(0x530),read_pl_reg(0x530),read_pl_reg(0x540),read_pl_reg(0x544));

			if(opc == 0x1) //write
			{
				req_element[sq_id].checkpoint_end = send_pcie_read_tlp(0x40000000+LBA_UNIT_SIZE*pba+block_offset, prp_arr[prp_index]+prp_offset, tlp_len/4);
				if(req_element[sq_id].checkpoint_start == 0)
				{
					req_element[sq_id].checkpoint_start = req_element[sq_id].checkpoint_end;
					/*xil_printf("R%x:",req_element[sq_id].checkpoint_start);
					for(u32 i=0; i<0x10; i++)
						xil_printf(" %x",cmd_addr[i]);
					xil_printf("\r\n");*/
					//xil_printf("R");
				}
			}
			else //read
			{
				req_element[sq_id].checkpoint_end = send_pcie_write_tlp(0x40000000+LBA_UNIT_SIZE*pba+block_offset, prp_arr[prp_index]+prp_offset, tlp_len/4);
				/*xil_printf("W%x:",req_element[sq_id].checkpoint_end);
				for(u32 i=0; i<0x10; i++)
					xil_printf(" %x",cmd_addr[i]);
				xil_printf("\r\n");*/
				//xil_printf("W");
			}

			mem_addr += (u64)tlp_len;

			if(tlp_len_arr_index != tlp_len_arr_len)
				prp_offset += tlp_len;
		}
	}
	else
	{
		req_element[sq_id].exec_state = 2;
	}
}

static void post_io_completion(u32 sq_id)
{
	NVME_REQ_BUF_ELEMENT *req_element = NVME_IO1_REQ_BUF_ADDR;
	u32 *cmd_addr = req_element[sq_id].cmd_addr;
	u32 opc = cmd_addr[0] & 0xff;
	
	//xil_printf("post_io_completion: %x %x\r\n",sq_id,opc);
	
	u32 next_sq_id = sq_id + 1;
	if(next_sq_id == io1_sq_size)
		next_sq_id = 0;


	cmd_addr[3] = (0 << 17) | io1_phase_tag | (cmd_addr[0] >> 16);
	cmd_addr[0] = 0;
	cmd_addr[1] = 0;
	cmd_addr[2] = (1 << 16) | (next_sq_id & 0xffff);

	
	//xil_printf("t%d: %x %x %x %x\r\n",io1_cq_tail_now,cmd_addr[0],cmd_addr[1],cmd_addr[2],cmd_addr[3]);
	
	req_element[sq_id].pcie_rw = 1;
	req_element[sq_id].checkpoint_start = read_pl_reg(0x40c); //req_overlap_origin+req_pointer_origin
	req_element[sq_id].checkpoint_end = send_pcie_write_tlp(cmd_addr, io1_cq_base_addr+io1_cq_tail_now*0x10, 4);
	
	io1_cq_tail_now++;
	if(io1_cq_tail_now == io1_cq_size)
	{
		io1_cq_tail_now = 0;
		io1_phase_tag ^= 0x10000;
	}
}