#ifndef FREERTOS_WRAPPER_H_
# define FREERTOS_WRAPPER_H_

#include "FreeRTOS.h"
#include "queue.h"

xQueueHandle w_xQueueCreate(unsigned portBASE_TYPE uxQueueLength,
							unsigned portBASE_TYPE uxItemSize);

signed portBASE_TYPE w_xQueueReceive(xQueueHandle xQueue,
									 void * const pvBuffer,
									 portTickType xTicksToWait);

signed portBASE_TYPE w_xQueueSend(xQueueHandle xQueue, 
								  const void * const pvItemToQueue,
								  portTickType xTicksToWait);
#endif /* !FREERTOS_WRAPPER_H_ */
