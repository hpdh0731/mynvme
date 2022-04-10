#include "pcie_data_buf.h"

volatile u32 pcie_data_buf_occupied_start = 0;
volatile u32 pcie_data_buf_occupied_end = 0;

void init_data_buf()
{
	pcie_data_buf_occupied_start = PCIE_DATA_BUF_ADDR;
	pcie_data_buf_occupied_end = PCIE_DATA_BUF_ADDR;
} 

u32 allocate_data_buf(u32 len)
{
	if(len%8) len+= 8-(len%8); //to align with axi4 64-bit burst
	
	if( pcie_data_buf_occupied_end >= pcie_data_buf_occupied_start )
	{
		if(BRAM_END_ADDR - pcie_data_buf_occupied_end > len + sizeof(PCIE_DATA_BUF_HEADER))
		{
			;
		}
		else if(pcie_data_buf_occupied_start - PCIE_DATA_BUF_ADDR > len + sizeof(PCIE_DATA_BUF_HEADER))
		{
			((PCIE_DATA_BUF_HEADER*)pcie_data_buf_occupied_end)->valid = 0;
			((PCIE_DATA_BUF_HEADER*)pcie_data_buf_occupied_end)->buf_len = BRAM_END_ADDR - pcie_data_buf_occupied_end - sizeof(PCIE_DATA_BUF_HEADER);
			
			pcie_data_buf_occupied_end = PCIE_DATA_BUF_ADDR;
		}
		else
			goto full;
	}
	else
	{
		if(pcie_data_buf_occupied_start - pcie_data_buf_occupied_end > len + sizeof(PCIE_DATA_BUF_HEADER))
		{
			;
		}
		else
			goto full;
	}
	
	((PCIE_DATA_BUF_HEADER*)pcie_data_buf_occupied_end)->valid = 1;
	((PCIE_DATA_BUF_HEADER*)pcie_data_buf_occupied_end)->buf_len = len;
	
	u32 data_ptr = pcie_data_buf_occupied_end + sizeof(PCIE_DATA_BUF_HEADER);
	pcie_data_buf_occupied_end += len + sizeof(PCIE_DATA_BUF_HEADER);
	
	return data_ptr;
	
full:
	//xil_printf("data buf full: %x %x %x\r\n",pcie_data_buf_occupied_end,pcie_data_buf_occupied_start,len);
	return NIL;
}

void invalid_data_buf(PCIE_DATA_BUF_HEADER * addr)
{
	addr--;
	addr->valid = 0;
	//xil_printf("invalid %x\r\n",addr);
}

void release_data_buf()
{
	while(1)
	{
		if(pcie_data_buf_occupied_start == pcie_data_buf_occupied_end)
			break;
		
		if(((PCIE_DATA_BUF_HEADER*)pcie_data_buf_occupied_start)->valid)
			break;
		
		//xil_printf("release data buf: %x\r\n",((PCIE_DATA_BUF_HEADER*)pcie_data_buf_occupied_start)->buf_len);
		pcie_data_buf_occupied_start += sizeof(PCIE_DATA_BUF_HEADER) + ((PCIE_DATA_BUF_HEADER*)pcie_data_buf_occupied_start)->buf_len;
		if(pcie_data_buf_occupied_start >= BRAM_END_ADDR)
			pcie_data_buf_occupied_start = PCIE_DATA_BUF_ADDR;
	}
}
