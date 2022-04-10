#ifndef _NVME_CMD_H_
#define _NVME_CMD_H_

#include "xparameters.h"
#include "gpio.h"
#include "pcie_req.h"
#include "lb2pb.h"

#define PCIE_RCB 0x40
#define NVME_ADMIN_REQ_BUF_ADDR 0x30100000 //length = 0x1A * admin_sq_size
#define NVME_IO1_REQ_BUF_ADDR 0x30104000 //length = 0x1A * io0_sq_size

u32 update_db_reg();
void handle_nvme_admin_cmd();
void handle_nvme_io_cmd();
void handle_nvme_req();

typedef struct nvme_req_buf
{
	u8 exec_state;
	u8 pcie_rw;
	u32 cmd_addr;
	u32 prp_addr;
	u32 exec_addr;
	union {
		struct {
			u32 checkpoint_start;
			u32 checkpoint_end;
		};
		struct {
			u16 req_pointer_origin;
			u16 req_overlap_origin;
			u16 req_pointer_target;
			u16 req_overlap_target;
		};
	};
	u32 timeout_cnt;
} NVME_REQ_BUF_ELEMENT;


#endif 