; coldstart1st.asm
;Холодный старт ОС. Программа располагается в ПЗУ начиная с адреса 0000H.
;Программа копирует подпрограмму 'coldstart2nd.asm' на адрес E000H и передает ей управление.
;
;Сборка ОС:
;   0000H - coldstart1st.bin
;   0030H - coldstart2nd.bin
;   0060H - supervisor.bin
;   1031H - libraries_F001.bin

.include /home/victor/Desktop/BarsikOS-2/core/systemdef.def
.include /home/victor/Desktop/BarsikOS-2/core/smm.def

.def Copy_Metka_1 =     $0030

    .org    $0000
;(1) Инициализация стека и портов
    mvi     a,88H
    out     SYSPORT_INI
    lxi     sp,$DFFF
;(2) Копировать подпрограмму coldstart2nd.asm на адрес E000H
    lxi     d,Copy_Metka_1
    lxi     h,$E000
    lxi     b,$1FC0     ;копируем 2 сектора
    call    COPCOUNT_CS1
;(3) Переход на E000H
    jmp     $E000
;-------------------------------------------------------------------------------
; Функция COPCOUNT - копирование массивов памяти
; Ввод: HL - адрес "куда копируем"
;       DE - адрес "откуда копируем"
;       BC - количество копируемых ячеек памяти
; Вывод: нет
; Используемые регистры: все
; Длина: 15 байт
; Время выполнения: -
COPCOUNT_CS1:
    inr     b
    inr     c
str_copcount_cs1_1:
    dcr     c
    jnz     str_copcount_cs1_2
    dcr     b
    rz
str_copcount_cs1_2:
    ldax    d
    mov     m,a
    inx     h
    inx     d
    jmp     str_copcount_cs1_1
;-------------------------------------------------------------------------------
    .org    Copy_Metka_1
