; coldstart2nd.asm
;Начальная загрузка ОС, программа номер 2
;Программа должна ассемблироваться с адреса E000H

.include /home/victor/Desktop/BarsikOS-2/core/systemdef.def
.include /home/victor/Desktop/BarsikOS-2/core/smm.def

.def Hot_Start_OS =     $0021
.def Copy_Metka_2 =     $E030

;-------------------------------------------------------------------------------
    .org    $E000
;(1) Переключение банков памяти: режим 1
    in      SYSPORT_A
    ori     SYS_MS0_BITMASK
    out     SYSPORT_A
;(2) Копировать главное тело ОС в начало адресного пространства
    lxi     d,Copy_Metka_2
    lxi     h,$0000
    lxi     b,$0F90     ;копируем 1 сектор
    call    COPCOUNT_CS2
;(3) Переход к горячему старту операционной системы
    jmp     Hot_Start_OS
;-------------------------------------------------------------------------------
; Функция COPCOUNT - копирование массивов памяти
; Ввод: HL - адрес "куда копируем"
;       DE - адрес "откуда копируем"
;       BC - количество копируемых ячеек памяти
; Вывод: нет
; Используемые регистры: все
; Длина: 15 байт
; Время выполнения: -
COPCOUNT_CS2:
    inr     b
    inr     c
str_copcount_cs2_1:
    dcr     c
    jnz     str_copcount_cs2_2
    dcr     b
    rz
str_copcount_cs2_2:
    ldax    d
    mov     m,a
    inx     h
    inx     d
    jmp     str_copcount_cs2_1
;-------------------------------------------------------------------------------
    .org    Copy_Metka_2
