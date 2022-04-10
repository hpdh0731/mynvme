#include "pcie_req.h"

volatile u32 pcie_req_read_tail = 0;
volatile u32 pcie_req_write_tail = 0;

void wait_pcie_init()
{
	while(1){
		write_pl_reg(0x400,PCIE_READ_REQ_BUF_ADDR);
		write_pl_reg(0x404,PCIE_WRITE_REQ_BUF_ADDR);

		 if(read_pl_reg(0x400) == PCIE_READ_REQ_BUF_ADDR && read_pl_reg(0x404) == PCIE_WRITE_REQ_BUF_ADDR)
			break;

		usleep(100);
	}
	write_pl_reg(0x104,0x1); //disable pcie record lock
	write_pl_reg(0x700, 0);
	//write_pl_reg(0x700, (0x10 << 16) | 0x10);
	//write_pl_reg(0x704, (0x1000 << 16) | 0x0);
	write_pl_reg(0x704, 0);

	xil_printf("pcie setting done\r\n");
}

u32 send_pcie_read_tlp(u32 data, u64 addr, u32 len)
{
	//xil_printf("send_pcie_read_tlp: 0x%x%08x,0x%x,0x%x",(u32)(addr>>32),(u32)(addr&0xffffffff),data,len);
	while(1)
	{
		u32 pcie_req_read_head = read_pl_reg(0x410) & 0xffff;
		
		u32 diff = pcie_req_read_head - pcie_req_read_tail;
		if((diff & (PCIE_REQ_LEN-1)) != sizeof(PCIE_REQ_BUF_ELEMENT)) // != full
			break;
	}	
	//xil_printf(".\r\n");
	
	volatile PCIE_REQ_BUF_ELEMENT *pcie_req = PCIE_READ_REQ_BUF_ADDR + pcie_req_read_tail;
	
	pcie_req->pcie_req_addr = addr;
	pcie_req->pcie_req_len = len;
	pcie_req->pcie_data_addr = data;

	pcie_req_read_tail += sizeof(PCIE_REQ_BUF_ELEMENT);
	if(pcie_req_read_tail >= PCIE_REQ_LEN)
		pcie_req_read_tail = 0;
	write_pl_reg(0x408, (pcie_req_write_tail << 16) | pcie_req_read_tail);

	start_pcie_req();
	
	return pcie_req;
}

u32 send_pcie_write_tlp(u32 data, u64 addr, u32 len)
{
	//xil_printf("send_pcie_write_tlp: 0x%x%08x,0x%x,0x%x",(u32)(addr>>32),(u32)(addr&0xffffffff),data,len);
	while(1)
	{
		u32 pcie_req_write_head = read_pl_reg(0x40c) & 0xffff;
		
		u32 diff = pcie_req_write_head - pcie_req_write_tail;
		if((diff & (PCIE_REQ_LEN-1)) != sizeof(PCIE_REQ_BUF_ELEMENT)) // != full
			break;
	}
	//xil_printf(".\r\n");
	
	volatile PCIE_REQ_BUF_ELEMENT *pcie_req = PCIE_WRITE_REQ_BUF_ADDR + pcie_req_write_tail;
	
	pcie_req->pcie_req_addr = addr;
	pcie_req->pcie_req_len = len;
	pcie_req->pcie_data_addr = data;
	
	u32 reg40c = read_pl_reg(0x40c);
	u16 req_pointer_now = reg40c & 0xffff;
	u16 req_overlap_now = reg40c >> 16;

	pcie_req_write_tail += sizeof(PCIE_REQ_BUF_ELEMENT);
	if(pcie_req_write_tail >= PCIE_REQ_LEN)
		pcie_req_write_tail = 0;
	write_pl_reg(0x408, (pcie_req_write_tail << 16) | pcie_req_read_tail);
	
	if(req_pointer_now > pcie_req_write_tail)
	{
		req_overlap_now++;
	}
		
	start_pcie_req();
	
	return (req_overlap_now << 16) | pcie_req_write_tail;
}

void send_msi(u32 vector)
{
	write_pl_reg(0x804,vector);
}
