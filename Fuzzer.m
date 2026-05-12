#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <dlfcn.h>

void startIOKitFuzzing(void) {
    printf("=== Запуск ObjC фаззера IOKit ===\n");
    
    // В iOS kIOMasterPortDefault недоступен, используем 0 (правильное значение для iOS)
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching("IOSurface"));
    
    if (service == IO_OBJECT_NULL) {
        printf("❌ IOSurface сервис не найден\n");
        return;
    }
    
    printf("✅ IOSurface сервис открыт\n");
    
    io_connect_t connect = IO_OBJECT_NULL;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
    
    if (kr != KERN_SUCCESS) {
        printf("❌ Не удалось открыть IOSurface (0x%x)\n", kr);
        IOObjectRelease(service);
        return;
    }
    
    printf("✅ Соединение установлено\n");
    
    // Фаззим селекторы с корректными типами для iOS
    for (int i = 0; i < 50; i++) {
        uint64_t input[32] = {0};  
        uint64_t output[32] = {0}; 
        uint32_t outputCount = 32; 
        
        kr = IOConnectCallMethod(connect, i,
                                 NULL, 0,
                                 input, sizeof(input),
                                 output, &outputCount,
                                 NULL, NULL);
        
        if (kr != KERN_SUCCESS && kr != kIOReturnUnsupported) {
            printf("⚠️ Селектор %d вернул 0x%x\n", i, kr);
        } else if (kr == KERN_SUCCESS) {
            printf("✅ Селектор %d выполнен успешно\n", i);
        }
    }
    
    IOServiceClose(connect);
    IOObjectRelease(service);
    printf("✅ Фаззинг завершён\n");
}
