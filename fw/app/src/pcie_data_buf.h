#ifndef _PCIE_DATA_BUF_H_
#define _PCIE_DATA_BUF_H_

#define NIL 0xFFFFFFFF

#include "xparameters.h"
#include "gpio.h"

typedef struct pcie_data_buf_header
{
	u32 valid;
	u32 buf_len;
} PCIE_DATA_BUF_HEADER;

#define PCIE_DATA_BUF_ADDR 0x30018000
#define BRAM_END_ADDR 0x30030000
#define DUMMY_BRAM_ADDR 0x30038000

void init_data_buf();
u32 allocate_data_buf(u32 len);
void invalid_data_buf(PCIE_DATA_BUF_HEADER* addr);
void release_data_buf();

#endif