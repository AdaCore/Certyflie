#include "FreeRTOS_wrapper.h"

xQueueHandle w_xQueueCreate(unsigned portBASE_TYPE uxQueueLength,
                    unsigned portBASE_TYPE uxItemSize)
{
    return xQueueGenericCreate(uxQueueLength,
                               uxItemSize,
                               queueQUEUE_TYPE_BASE );
}

int w_xQueueReceive(xQueueHandle xQueue,
                    void * const pvBuffer,
                    portTickType xTicksToWait)
{
    signed portBASE_TYPE res = xQueueGenericReceive(xQueue,
                                                    pvBuffer,
                                                    xTicksToWait,
                                                    pdFALSE);

    if (res == pdTRUE)
        return 0;
    else
        return -1;
}

int w_xQueueSend(xQueueHandle xQueue,
                 const void * const pvItemToQueue,
                 portTickType xTicksToWait)
{
    signed portBASE_TYPE res = xQueueGenericSend(xQueue,
                                                 pvItemToQueue,
                                                 xTicksToWait,
                                                 queueSEND_TO_BACK);

    if (res == pdTRUE)
        return 0;
    else
        return -1;
}
