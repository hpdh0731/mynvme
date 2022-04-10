#include "nvme_identify.h"

void identify_controller(IDENTIFY_CONTROLLER_STRUCTURE* buf)
{
	memset(buf, 0, sizeof(IDENTIFY_CONTROLLER_STRUCTURE));

	buf->VID = PCI_VENDOR_ID;
	buf->SSVID = PCI_SUBSYSTEM_VENDOR_ID;

	memset(buf->SN, 0x20, 20);
	memcpy(buf->SN, SERIAL_NUMBER, sizeof(SERIAL_NUMBER));

	memset(buf->MN, 0x20, 40);
	memcpy(buf->MN, MODEL_NUMBER, sizeof(MODEL_NUMBER));

	memset(buf->FR, 0x20, 8);
	memcpy(buf->FR, FIRMWARE_REVISION, sizeof(FIRMWARE_REVISION));

	buf->MDTS = 0x1;

	buf->SQES.requiredQueueEntrySize = 0x6;
	buf->SQES.maximumQueueEntrySize = 0x6;

	buf->CQES.requiredQueueEntrySize = 0x4;
	buf->CQES.maximumQueueEntrySize = 0x4;

	buf->NN = 0x1;

	buf->VWC = 0x1;
}

void identify_namespace(IDENTIFY_NAMESPACE_STRUCTURE* buf)
{
	memset(buf, 0, sizeof(IDENTIFY_NAMESPACE_STRUCTURE));

	buf->NSZE[0] = STORAGE_SIZE & 0xffffffff;
	buf->NSZE[1] = (STORAGE_SIZE >> 32) & 0xffffffff;
	buf->NCAP[0] = STORAGE_SIZE & 0xffffffff;
	buf->NCAP[1] = (STORAGE_SIZE >> 32) & 0xffffffff;
	buf->NUSE[0] = STORAGE_SIZE & 0xffffffff;
	buf->NUSE[1] = (STORAGE_SIZE >> 32) & 0xffffffff;

	buf->LBAF0.MS = 0x0;
	buf->LBAF0.LBADS = 0xC;
	buf->LBAF0.RP = 0x2;
}

