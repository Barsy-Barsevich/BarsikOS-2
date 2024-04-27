; Supervisor - главное тело 0000H
; (E) Barsotion BarsikOS-2.17 (22.12.2023)

.include /home/victor/Desktop/BarsikOS-2/core/systemdef.def
.include /home/victor/Desktop/BarsikOS-2/core/smm.def
.include /home/victor/Desktop/BarsikOS-2/core/libraries.h

;Вектор $0000 - фатальная ошибка
    .org    $0000
    jmp     FATAL_ERROR_HANDLER
;Вектор $0003 - ошибка диска
    .org    $0003
    jmp     DISK_ERROR_HANDLER


;Вектор 21H - Горячий старт ОС
    .org    $0021
    jmp     Hot_Start_OS


;Вектор 24Н - Инквизитор
;===============================================================================
;-<Инквизитор>------------------------------------------------------------------
    .org 0024H
TRAP_main:
    push    psw
    push    b
    push    d
    push    h
;(1) Определяем, кто был источником прерывания
    rim             ;Чтение маски прерываний
    mov     b,a
;Сбрасываем RST7.5
    mvi     a,$10
    sim
    mov     a,b
    ani     $40     ;Выделяем RST7.5
    jz      TRAP_source_proc
;===============================================================================
;-<(1a) Источник прерывания - таймер>-------------------------------------------
;-<Диспетчер задач>-------------------------------------------------------------
TRAP_source_timer:
TRAP_Planner:
;--<Откладываем текущий процесс>------------------------------------------------
;(1) Нахождение указателя на САП, который следует отложить
    lda     SYSCELL_TEMP_PROC_NUM
    mov     e,a
    xra     a
    mov     d,a     ;очистка D и CY
    rdel
    rdel
    rdel
    rdel
    rdel            ;DE <- TEMP_PROC_NUM*32
    lhld    SYSCELL_SAP_STARTADDR
    ;lxi     h,SAP_STARTADDR
    dad     d       ;HL - указатель на САП
    shld    SYSCELL_PROCTOARCH
; [HL]
; [DE]
; [BC]
; [PSW]
; [USER]
;(2) Откладываем текущий процесс (загрузка в САП сод. РОН и адрес возврата)
    ldhi    SYSPA_STACK_HL
    xchg
    mvi     c,$05
planner_m0:
    pop     d   ;[HL],[DE],[BC],[PSW],[USER]
    mov     m,e
    inx     h
    mov     m,d
    inx     h
    dcr     c
    jnz     planner_m0
;(3) Загружаем в САП содержимое регистра SP
    lhld    SYSCELL_PROCTOARCH      ;HL-указатель на САП
    ldhi    SYSPA_SP_REG
    lxi     h,$0000                 ;HL <- SP
    dad     sp
    shlx
;--<Поиск нового процесса для запуска>------------------------------------------
;Стек сейчас не содержит ничего важного для работы ОС
;Да операционке вообще неважно, что сейчас в стеке, все равно SP будем менять
planner_change_proc:
;(1) Инкремент номера текущего процесса, если >= числа процессов, придаем 0
    lda     SYSCELL_NUM_OF_PROC
    mov     b,a
    lda     SYSCELL_TEMP_PROC_NUM
    inr     a
    cmp     b
    jc      planner_m1
    xra     a
planner_m1:
    sta     SYSCELL_TEMP_PROC_NUM
;(2) Указатель на САП = SAP_START + (TEMP_PROC_NUM * 32)
    mov     e,a
    xra     a
    mov     d,a
    rdel                ;DE <- TEMP_PROC_NUM*32
    rdel
    rdel
    rdel
    rdel
    ;lxi     h,SAP_STARTADDR
    lhld    SYSCELL_SAP_STARTADDR
    dad     d           ;HL - указатель на САП
    shld    SYSCELL_PROCTORUN ;указатель на САП процесса, который надо запустить
;(3) Проверка статуса.
; - Если 00, то запуск
; - Если 01, то выбор новой САП
; - Если 10, то выбор новой САП
; - Если 11, то поиск процесса-условия, выполнен - запуск, нет - выбор новой САП
    ldhi    SYSPA_STATUS_0
    ldax    d
    ani     SYSPA_STATUS_STATUS_MASK
    cpi     SYSPA_PROC_LAUNCHED
    jz      planner_run_proc
    cpi     SYSPA_PROC_WAITING
    jnz     planner_change_proc ;SYSPA_PROC_STOPPED & SYSPA_PROC_COMPLETED
;(4) Поиск САП с нужным ID
;Байт ID - 0й байт САП (дескриптора процесса)
;В цикле NUM_OF_PROC раз перебираем САП, если совпадение - смотрим биты статуса
;SYSPA_STATUS_STATUS_MASK. Если равны SYSPA_PROC_COMPLETED, то начальный
;процесс завершен, а значит, вторичный может начинать работу. Если не равен
;SYSPA_PROC_COMPLETED, переход к planner_change_proc. Если процесс с нужным ID
;не найден, запуск ждущего процесса(v2.20) /переход к planner_change_proc(v2.19)
;Выделение байта ID первичного процесса
    lda     SYSCELL_NUM_OF_PROC
    mov     c,a                     ;C <- NUM_OF_PROC
    lhld    SYSCELL_PROCTORUN
    ldhi    SYSPA_STATUS_1
    ldax    d                       ;A <- ID
    lhld    SYSCELL_SAP_STARTADDR   ;HL <- SAP_STARTADDR
    lxi     d,ONE_SAP_LEN           ;DE <- 32
;(5) Цикл-пробежка по очереди САП
planner_cycle:
    cmp     m
    jz      planner_m2
    dad     d
    dcr     c
    jnz     planner_cycle
;В версии v2.20 изменяется условие запуска ждущего процесса: если дескриптор
;ожидаемого процесса не найден, то запуск ждущего процесса
;    jmp     planner_change_proc  ;v2.19
    jmp     planner_run_proc
;(6) Определить, выполнен первичный процесс или еще выполняется
;HL - указатель на САП первичного процесса
planner_m2:
    ldhi    SYSPA_STATUS_0
    ldax    d
    ani     SYSPA_STATUS_STATUS_MASK
    cpi     SYSPA_PROC_COMPLETED
    jz      planner_run_proc
    jmp     planner_change_proc
;--<Запуск нового процесса>-----------------------------------------------------
planner_run_proc:
;(1) Выгружаем из САП содержимое регистра SP
    lhld    SYSCELL_PROCTORUN       ;HL-указатель на САП
    ldhi    SYSPA_SP_REG
    lhlx
    sphl
;(2) Подготавливаем стек под новый процесс
    lhld    SYSCELL_PROCTORUN       ;HL-указатель на САП
    ldhi    SYSPA_H_RETADDR
    xchg
    mvi     c,$05
planner_m3:
    mov     d,m
    dcx     h
    mov     e,m
    dcx     h
    push    d   ;[USER],[PSW],[BC],[DE],[HL]
    dcr     c
    jnz     planner_m3
;(3) Загружаем таблицу ассоциаций для нового процесса
    lhld    SYSCELL_PROCTORUN
    call    SYS_TA_write
;(4) Загружаем размер кванта времени для нового процесса
    lhld    SYSCELL_PROCTORUN
    call    SYS_QuantTime_Set
;(5) Фиксируем текущее машинное время в микросекундах
    call    SYS_Read_Time_Ms
    shld    SYSCELL_TIME_PROC_MARK
    ;
    jmp     TRAP_source_end
;===============================================================================
;-<(1b) Источник прерывания - процесс>------------------------------------------
TRAP_source_proc:
;Получение значения адреса старшего байта адреса процесса пользователя,
;откуда был выполнен переход в режим ОС
    lxi     h,$000B     ;смещение 11
    dad     sp          ;(HL)=(SP)+11
    mov     a,m         ;(A)-старший байт адреса процесса пользователя
    ani     $F0
    cpi     $F0         ;проверка на сектор 'F'
    ;cpi     $00         ;проверка на сектор '0'
    jz      TRAP_stack_form     ;переход к выполнению системной функции
;===============================================================================
;-<(1ba) Убийца процессов>------------------------------------------------------
    ;Смотрим SYSCELL_STARTPASS (Если не равен 0, то не убиваем. Установ в 0)
    lda     SYSCELL_STARTPASS
    mov     b,a
    xra     a
    sta     SYSCELL_STARTPASS
    mov     a,b
    ora     a
    jnz     TRAP_source_end     ;переход к стандартному выходу
;--<Таки убить>-----------------------------------------------------------------
;Стек не должен содержать к этому моменту никакой важной для ОС информации!
;Ну типа, если там есть какая-то важная информация, она потеряется
;--<Проверка на ожидаемость>----------------------------------------------------
    lhld    SYSCELL_PROCTORUN
    ldhi    SYSPA_STATUS_0
    ldax    d
    ani     SYSPA_STATUS_WAITED_MASK
;Если 0 - убрать процесс из QSAP
;Если 1 - пометить как завершенный
    jz      killer_from_qsap
;--<Пометить процесс как завершенный>-------------------------------------------
    ldhi    SYSPA_STATUS_0
    ldax    d
    ori     SYSPA_PROC_COMPLETED
    stax    d
;Переход к выбору следующей задачи
    jmp     planner_change_proc
;--<Удаление дескриптора процесса из очереди дескрипторов QSAP>-----------------
killer_from_qsap:
;(1) Найти следующий дескриптор процесса
    lda     SYSCELL_NUM_OF_PROC
    mov     c,a
    lda     SYSCELL_TEMP_PROC_NUM
    inr     a
    cmp     c   ;если temp_proc >= num_of_proc, CY:=0
;Если temp_proc >= num_of_proc, тогда адрес сл САП равен SAP_STARTADDR.
;Тогда ничего не делаем, просто декремент NUM_OF_PROC
    jnc     killer_m1
;NEXT_PROC равен TEMP_PROC+ONE_SAP_LEN. Копировать верхнюю часть QSAP на
;ONE_SAP_LEN вниз, затем декремент NUM_OF_PROC
;(2) DE <- NEXT_PROC := TEMP_PROC + ONE_SAP_LEN
    lxi     d,ONE_SAP_LEN
    lhld    SYSCELL_PROCTORUN
    dad     d
    xchg
;(3) BC <- 'сколько' := SAP_STARTADDR + QSAP_LEN - NEXT_PROC
    lhld    SYSCELL_SAP_STARTADDR
    lxi     b,QSAP_LEN
    dad     b
    mov     b,d
    mov     c,e
    dsub
    mov     b,h
    mov     c,l
;(4) HL <- SYSCELL_PROCTORUN
    lhld    SYSCELL_PROCTORUN
;(5) Копируем
    call    COPCOUNT
;(6) NUM_OF_PROC -= 1
killer_m1:
    lxi     h,SYSCELL_NUM_OF_PROC
    dcr     m
;(7) Переход к выбору следующей задачи
    jmp     planner_change_proc
;===============================================================================
;-<(1bb) Переход к исполнению системной функции>--------------------------------
TRAP_stack_form:
;Перестановка:
; [HL]          
; [DE]          [USR_MUUTOS]
; [BC]          [HL]
; [PSW]         [DE]
; [SYS_OS] ->   [BC]
; [FUN]         [PSW]
; [USER]   =    [USER]
; [DI]     =    [DI]
;Работаем:
    pop     psw     ;HL
    pop     b       ;DE
    pop     d       ;BC
    pop     h       ;PSW
    xthl            ;(HL)=[SYS_OS], (stack)=PSW
    pop     h       ;PSW
    xthl            ;(HL)=[FUN], (stack)=PSW
    push    d       ;BC
    push    b       ;DE
    push    psw     ;HL
;Загрузка указателя на подпрограмму TRAP_SystemFunction_Return
    lxi     d,TRAP_SystemFunction_Return
    push    d
;Переход к системной функции
    ;(HL)-адрес возврата [FUN]
    pchl
;===============================================================================
;-<Возврат из системной функции>------------------------------------------------
TRAP_SystemFunction_Return:
;Сравниваем текущее машинное время со временем последнего запуска процесса
    lhld    SYSCELL_TIME_PROC_MARK
    mov     b,h
    mov     c,l
    call    SYS_Read_Time_Ms
;(HL)<-(millis-metka)
    dsub
;Защита от downflow. Недополнение случается 1 раз в 32.768 сек, что больше
;на порядки максимальных размеров кванта времени, можно использовать модуль
    call    ABS
;Сохранить значение
    push    h
;Посчитать размер кванта времени для текущего процесса в мс
;(HL)<-(QuantTime/CLT_Ticks_Per_Ms)
    lhld    SYSCELL_QUANT_TIME
    lxi     d,CLT_Ticks_Per_Ms
    call    UDIV16
;Сравнить значения
    pop     d
    call    CMP16   ;C=0 - HL>=DE
;Если C=0, то квант времени не был привышен, возврат в процесс
    jnc     TRAP_source_end
;Иначе переход в диспетчер задач
    jmp     TRAP_Planner
;===============================================================================
;-<(2) Стандартный возврат>-----------------------------------------------------
TRAP_source_end:
    jmp     SYS_User_muutos
;===============================================================================





;---<Подпрограмма "Горячий старт ОС">-------------------------------------------
Hot_Start_OS:
;CLKE и Турборежим
    mvi     a,SYS_CLKE_BITMASK
    ;mvi     a,$05   ;SYS_CLKE_BITMASK | SYS_TURBO_BITMASK
    out     SYSPORT_C
;Пропуск в первый заход TRAP (вырубаем убийцу процессов)
    mvi     a,$01
    sta     SYSCELL_STARTPASS
;Загрузка указателя на очередь дескрипторов процессов (QSAP)
    lxi     h,SAP_STARTADDR
    shld    SYSCELL_SAP_STARTADDR
    
    mvi     a,$0A
    sta     $8010
;Инициализация TIMER1 в режим 3, коэффициент - CLT_Ticks_Per_Ms
    mvi     a,$76
    out     TIMER_MODEREG
    lxi     h,CLT_Ticks_Per_Ms
    mov     a,l
    out     TIMER_COUNTER_1
    mov     a,h
    out     TIMER_COUNTER_1
;Инициализация TIMER0 в режим 0
    mvi     a,$30
    out     TIMER_MODEREG
    mvi     a,$10
    out     TIMER_COUNTER_0
    mvi     a,$00
    out     TIMER_COUNTER_0
;Инициализация внешнего порта
    mvi     a,$88
    out     EXTPORT_INI
;Устанавливаем начальное значение дисплея
    mvi     a,$55
    out     DISP_PORT
;Копируем заголовки процессов
    mvi     b,$00
    mvi     a,ONE_SAP_LEN
    add     a
    mov     c,a
    lxi     d,SAP_STARTADDR_ROM
    ;lxi     h,SAP_STARTADDR
    lhld    SYSCELL_SAP_STARTADDR
    call    COPCOUNT
;Предзагрузка переменных диспетчера задач
    mvi     a,$02
    sta     SYSCELL_NUM_OF_PROC
;Начальный процесс - 0
    mvi     a,$00
    sta     SYSCELL_TEMP_PROC_NUM
; Включаем запись в банк регистров
    ;lxi     h,SAP_STARTADDR
    lhld    SYSCELL_SAP_STARTADDR
    call    SYS_TA_write
;Загружаем в стек переход к пользовательскому процессу
    lxi     h,process0
    ;lxi     h,$2000
    push    h
;Переход к TRAP
    jmp     TRAP_main
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
;---<System_process_attributes>-------------------------------------------------
;SAP_STARTADDR:
SAP_STARTADDR_ROM:
;--<1st process>----------------------------------------------------------------
.db $00     ;SYSPA_ID =         $00
.db $27     ;SYSPA_STATUS_0 =   $01
.db $00     ;SYSPA_STATUS_1 =   $02
;Table of Assotiations
.db $01     ;SYSPA_TA_01 =      $03
.db $23     ;SYSPA_TA_23 =      $04
.db $45     ;SYSPA_TA_45 =      $05
.db $67     ;SYSPA_TA_67 =      $06
.db $89     ;SYSPA_TA_89 =      $07
.db $AB     ;SYSPA_TA_AB =      $08
.db $CD     ;SYSPA_TA_CD =      $09
.db $EF     ;SYSPA_TA_EF =      $0A
;Contains of stack
.dw $0000   ;SYSPA_STACK_HL =   $0B
.dw $0000   ;SYSPA_STACK_DE =   $0D
.dw $0000   ;SYSPA_STACK_BC =   $0F
.dw $0000   ;SYSPA_STACK_PSW =  $11
;Return address
.dw process0   ;SYSPA_RETADDR =    $13
;Stack Pointer value
.dw $1FFF   ;SYSPA_SP_REG
;Зарезервированные байты
.db $00     ;SYSPA_RES0 =       $17
.db $00     ;SYSPA_RES1 =       $18
.db $00     ;SYSPA_RES2 =       $19
.db $00     ;SYSPA_RES3 =       $1A
.db $00     ;SYSPA_RES4 =       $1B
.db $00     ;SYSPA_RES5 =       $1C
.db $00     ;SYSPA_RES6 =       $1D
.db $00     ;SYSPA_RES7 =       $1E
.db $00     ;SYSPA_RES8 =       $1F
;--<2nd process>----------------------------------------------------------------
.db $01     ;SYSPA_ID =         $00
.db $87     ;SYSPA_STATUS =     $01
.db $00     ;SYSPA_STATUS2 =    $02
;Table of Assotiations
.db $33     ;SYSPA_TA_01 =      $03
.db $33     ;SYSPA_TA_23 =      $04
.db $33     ;SYSPA_TA_45 =      $05
.db $33     ;SYSPA_TA_67 =      $06
.db $33     ;SYSPA_TA_89 =      $07
.db $33     ;SYSPA_TA_AB =      $08
.db $33     ;SYSPA_TA_CD =      $09
.db $EF     ;SYSPA_TA_EF =      $0A
;Contains of stack
.dw $0000   ;SYSPA_STACK_HL =   $0B
.dw $0000   ;SYSPA_STACK_DE =   $0D
.dw $0000   ;SYSPA_STACK_BC =   $0F
.dw $0000   ;SYSPA_STACK_PSW =  $11
;Return address
.dw $3000   ;process1   ;SYSPA_RETADDR =    $13
;Stack Pointer value
.dw $3FFF   ;SYSPA_SP_REG
;Зарезервированные байты
.db $00     ;SYSPA_RES0 =       $17
.db $00     ;SYSPA_RES1 =       $18
.db $00     ;SYSPA_RES2 =       $19
.db $00     ;SYSPA_RES3 =       $1A
.db $00     ;SYSPA_RES4 =       $1B
.db $00     ;SYSPA_RES5 =       $1C
.db $00     ;SYSPA_RES6 =       $1D
.db $00     ;SYSPA_RES7 =       $1E
.db $00     ;SYSPA_RES8 =       $1F
;-------------------------------------------------------------------------------

;Библиотека системных функций
.include    /home/victor/Desktop/BarsikOS-2/core/SYStemFS.asm

;Обработчики программных прерываний
.include    /home/victor/Desktop/BarsikOS-2/core/errorh.asm

;.include /home/victor/Desktop/BarsikOS-2/lib/StandartArithmetic.asm
;.include /home/victor/Desktop/BarsikOS-2/lib/AFS3.asm


process0:

    lxi     h,$0500
    call    Delay_ms_6
    call    W25_Test
    
;    call    ST7920_INI
;    call    GR_INI
;;Установка таблицы шрифтов
;    lxi     h,$9000
;    push    h
;    call    GR_FONT
;    pop     h
;;Установка начального адреса видеобуфера
;    lxi     h,$C800
;    push    h
;    call    GR_START_BUF_ADDR
;    pop     h
;;Очистка видеобуфера, печать туда текста
;    call    ST7920_BUF_CLR
;    lxi     h,string_test
;    push    h
;    lxi     h,$000A
;    push    h
;    lxi     h,$0000
;    push    h
;    call    GR_STOPT
;    pop     h
;    pop     h
;    pop     h
;    call    ST7920_PRINT_BUF
;;Задержка
;    lxi     h,$01F4
;    call    Delay_ms_6
     
    mvi     a,$40
    sim
    mvi     a,$C0
    sim
    nop
    nop
    nop
    nop
    nop
    jmp     process0
    
    

process1:
    call    Read_Time
    jmp     $8330   ;process1

string_test:
.db $1C
.ds '(E)'
.db $20
.ds 'Barsotion'
.db $20
.ds 'BarsikOS-v2.1'
inc_metka:
.ds '0'
