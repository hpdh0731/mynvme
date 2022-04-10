#ifndef _NVME_IDENTIFY_H_
#define _NVME_IDENTIFY_H_

#include "xstatus.h"

#define PCI_VENDOR_ID				0x8086
#define PCI_SUBSYSTEM_VENDOR_ID		0x8086
#define SERIAL_NUMBER				"NCKU1234"
#define MODEL_NUMBER				"NVME2022"
#define FIRMWARE_REVISION			"12345678"


#define STORAGE_SIZE				0x40000 //1GB


typedef struct
{
	u16 VID;
	u16 SSVID;
	u8 SN[20];
	u8 MN[40];
	u8 FR[8];
	
	u8 reserved0[5];
	
	u8 MDTS;
	
	u8 reserved1[434];
	
	struct
	{
		u8 requiredQueueEntrySize			:4;
		u8 maximumQueueEntrySize			:4;
	} SQES;

	struct
	{
		u8 requiredQueueEntrySize			:4;
		u8 maximumQueueEntrySize			:4;
	} CQES;


	u8 reserved2[2];
	
	u32 NN;

	u8 reserved3[5];
	
	u8 VWC;
	
	u8 reserved4[3570];

} IDENTIFY_CONTROLLER_STRUCTURE;


typedef struct
{
	u32 NSZE[2];
	u32 NCAP[2];
	u32 NUSE[2];

	u8 reserved0[104];

	struct
	{
		unsigned short MS;
		unsigned char LBADS;
		unsigned char RP				:2;
		unsigned char reserved			:6;
	} LBAF0;

	u8 reserved1[3964];

} IDENTIFY_NAMESPACE_STRUCTURE;


void identify_controller(IDENTIFY_CONTROLLER_STRUCTURE*);

void identify_namespace(IDENTIFY_NAMESPACE_STRUCTURE*);


#endif
