#ifndef _NVME_SYS_GPIO_
#define _NVME_SYS_GPIO_

#include "xgpiops.h"
#include "xparameters.h"
#include "xstatus.h"

void wait_pcie_reset();

void init_gpio();

u32 read_pl_reg(u32 addr);

void write_pl_reg(u32 addr, u32 data);

#endif
