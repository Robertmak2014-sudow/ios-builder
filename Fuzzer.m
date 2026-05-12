#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <dlfcn.h>

void startIOKitFuzzing(void) {
    printf("=== Запуск ObjC фаззера IOKit ===\n");
    
    // Прямой доступ к IOKit без проблем с типами
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, 
                                                        IOServiceMatching("IOSurface"));
    
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
    
    // Фаззим селекторы
    for (int i = 0; i < 50; i++) {
        char input[256] = {0};
        char output[256] = {0};
        size_t outputSize = sizeof(output);
        
        kr = IOConnectCallMethod(connect, i,
                                 NULL, 0,
                                 input, sizeof(input),
                                 output, &outputSize,
                                 NULL, NULL);
        
        if (kr != KERN_SUCCESS) {
            printf("⚠️ Селектор %d вернул 0x%x\n", i, kr);
        } else {
            printf("✅ Селектор %d выполнен\n", i);
        }
    }
    
    IOServiceClose(connect);
    IOObjectRelease(service);
}
