#ifndef _NVME_PCIE_REQ_H_
#define _NVME_PCIE_REQ_H_

#include "xparameters.h"
#include "gpio.h"

#define PCIE_REQ_LEN 0x8000
#define PCIE_READ_REQ_BUF_ADDR  0x30040000 //Length = 0x8000
#define PCIE_WRITE_REQ_BUF_ADDR 0x30048000 //Length = 0x8000

typedef struct pcie_req_buf
{
	u64 pcie_req_addr;
	u32 pcie_req_len;
	u32 pcie_data_addr;
} PCIE_REQ_BUF_ELEMENT;

void wait_pcie_init();

u32 send_pcie_read_tlp(u32 data, u64 addr, u32 len);

u32 send_pcie_write_tlp(u32 data, u64 addr, u32 len);

void send_msi(u32 vector);

#endif 