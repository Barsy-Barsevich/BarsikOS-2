

;.def FATAL_ERROR_VECT =     $0000
;.def DISK_ERROR_VECT =      $0003


; (1) FATAL_ERROR_HANDLER
; Обработчик программного прерывания "Фатальная ошибка"
; Алгоритм: печать на экране значения 'F' с точкой, затем бесконечный цикл

FATAL_ERROR_HANDLER:
;Вывод на экран цифры F с точкой
    mvi     a,$46   ;'F'
    call    ASCSEG7
    ori     $80
    cma
    out     DISP_PORT
sys_feh_cycle:
    jmp     sys_feh_cycle


; (2) DISK_ERROR_HANDLER
; Обработчик программного прерывания "Ошибка диска"
; Алгоритм: печать на экране значения 'd' с точкой, затем бесконечный цикл

DISK_ERROR_HANDLER:
    mvi     a,$44   ;'D'
    call    ASCSEG7
    ori     $80
    cma
    out     DISP_PORT
sys_deh_cycle:
    jmp     sys_deh_cycle
