#include "FreeRTOS_wrapper.h"

xQueueHandle w_xQueueCreate( unsigned portBASE_TYPE uxQueueLength, unsigned portBASE_TYPE uxItemSize)
{
    return xQueueGenericCreate(uxQueueLength,
    						   uxItemSize,
    						   queueQUEUE_TYPE_BASE );
}

signed portBASE_TYPE w_xQueueReceive(xQueueHandle xQueue,
									 void * const pvBuffer,
									 portTickType xTicksToWait)
{
	return xQueueGenericReceive(xQueue, pvBuffer, xTicksToWait, pdFALSE);
}

signed portBASE_TYPE w_xQueueSend(xQueueHandle xQueue,
								  const void * const pvItemToQueue,
								  portTickType xTicksToWait)
{
	return xQueueGenericSend(xQueue, pvItemToQueue, xTicksToWait, queueSEND_TO_BACK);
}
