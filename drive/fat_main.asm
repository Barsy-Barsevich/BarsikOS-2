
;.def SYSCELL_DISKBUF_ADDR =     $FF1E
;.def SYSCELL_STRBUF8 =          $FF20
;.def SYSCELL_STRBUF8P1 =        $FF21

.def DISK_CLUSTER_ERASE =   W25_SECTOR_ERASE
.def DISK_CLUSTER_WRITE =   W25_SECTOR_WRITE
.def DISK_CLUSTER_READ =    W25_SECTOR_READ


;===============================================================================
;---<Имя корневого каталога>----------------------------------------------------
;Имя и расширение
.def FAT_DESCR_NAME =           $00
.def FAT_DESCR_NAME_0 =         $00
.def FAT_DESCR_NAME_1 =         $01
.def FAT_DESCR_NAME_2 =         $02
.def FAT_DESCR_NAME_3 =         $03
.def FAT_DESCR_NAME_4 =         $04
.def FAT_DESCR_NAME_5 =         $05
.def FAT_DESCR_NAME_6 =         $06
.def FAT_DESCR_NAME_7 =         $07
.def FAT_DESCR_FORM =           $08
.def FAT_DESCR_FORM_0 =         $08
.def FAT_DESCR_FORM_1 =         $09
.def FAT_DESCR_FORM_2 =         $0A
;Статус 
.def FAT_DESCR_STATUS =         $0B
;Зарезервировано
.def FAT_DESCR_RES_0 =          $0C
.def FAT_DESCR_RES_1 =          $0D
.def FAT_DESCR_RES_2 =          $0E
.def FAT_DESCR_RES_3 =          $0F
.def FAT_DESCR_RES_4 =          $10
.def FAT_DESCR_RES_5 =          $11
.def FAT_DESCR_RES_6 =          $12
.def FAT_DESCR_RES_7 =          $13
.def FAT_DESCR_RES_8 =          $14
.def FAT_DESCR_RES_9 =          $15
;Дата последнего изменения
.def FAT_DESCR_DATE_0 =         $16
.def FAT_DESCR_DATE_1 =         $17
.def FAT_DESCR_DATE_2 =         $18
.def FAT_DESCR_DATE_3 =         $19
;Указатель на первый кластер файла или субдиректории
.def FAT_DESCR_FSTCLUST =       $1A
.def FAT_DESCR_FSTCLUST_L =     $1A
.def FAT_DESCR_FSTCLUST_H =     $1B
;Размер файла или субдиректории
.def FAT_DESCR_SIZE =           $1C
.def FAT_DESCR_SIZE_0 =         $1C
.def FAT_DESCR_SIZE_1 =         $1D
.def FAT_DESCR_SIZE_2 =         $1E
.def FAT_DESCR_SIZE_3 =         $1F
;===============================================================================
;--<Аттрибуры директории>-------------------------------------------------------
;|n/u|n/u|Archive|Subdir|???|System|Hidden|ReadOnly|
;|0  |0  |0      |1     |0  |1     |0     |0       |
.def FAT_STATUS_ARCHIVE_MASK =  $20
.def FAT_STATUS_ARCHIVE_NMASK = $DF
.def FAT_STATUS_SUBDIR_MASK =   $10
.def FAT_STATUS_SUBDIR_NMASK =  $EF
.def FAT_STATUS_SYSTEM_MASK =   $04
.def FAT_STATUS_SYSTEM_NMASK =  $FB
.def FAT_STATUS_HIDDEN_MASK =   $02
.def FAT_STATUS_HIDDEN_NMASK =  $FD
.def FAT_STATUS_RONLY_MASK =    $01
.def FAT_STATUS_RONLY_NMASK =   $FE
;===============================================================================




; FAT_Set_Pointer_To_Root - установка указателя директории на root-директорию
; Ввод: нет
; Вывод: нет
; Используемая память: SYSCELL_FAT_POINTER (word)
; Оценка: длина - , время - 
FAT_SET_POINTER_TO_ROOT:
FAT_SPR:
    lxi     h,FAT_START_POINTER
    shld    SYSCELL_FAT_POINTER
    ret


; FAT_FIND_NEXT_CLUSTER - поиск номера следующего кластера файла/субдиректории
; Ввод:  (SP+2) - номер текущего кластера
; Вывод: (SP+2) - номер следующего кластера
;        Флаг C - если равен 0, то успешно, если 1, то следующего кластера нет
; Используемые регистры: все
; Читаемая память: SYSCELL_DISKBUF_ADDR
; Используемая память:
;  - массив DISKBUF (длины $1000)
; Используемые функции:
;  - DISK_CLUSTER_READ
;  - CMP16
; Оценка: длина - , время - 

FAT_FIND_NEXT_CLUSTER:
;Копируем кластер FAT в буфер
    lxi     h,FAT_CLUSTER
    push    h
    lhld    SYSCELL_DISKBUF_ADDR
    push    h
    call    DISK_CLUSTER_READ
;По адресу (SYSCELL_DISKBUF_ADDR+CLUST_NUM) считываем значение NEXT
    pop     b
    pop     d   ;Помни об адресе возврата!!!!!!!!!!!
    push    b
    lhld    SYSCELL_DISKBUF_ADDR
    dad     d   ;Потому что на 1 кластер 2 байта в таблице FAT!!!!!!!!!!
    dad     d
    ;mov     e,m
    ;inx     h
    ;mov     d,m
    ;xchg        ;(HL)-NEXT
    xchg
    lhlx
;Сравниваем NEXT c $FFF0
    lxi     d,$FFF0
    call    CMP16   ;если C==0, то ошибка
    cmc             ;если С==1, то ошибка
    xchg
    pop     h
    push    d
    pchl



; FAT_FIND_BY_NAME - поиск номера первого кластера файла/субдиректории по имени
; Ввод:  (SP+4) - начальный адрес строки, сод имя искомого файла
;        (SP+2) - номер начального кластера директории, в которой ведем поиск
; Вывод: (SP+4) - номер первого кластера найденного файла/субдиректории
;        (SP+2) - статус найденного файла/субдиректории
;        Флаг С - если равен 0, то успешно, если 1, то не удалось найти
; Используемые регистры: все
; Используемая память:
;  - массив DISKBUF (длины $1000)
;  - SYSCELL_FAT_SF_STATUS (byte)
;  - SYSCELL_FAT_SF_LEN (uint32_t)
; Используемые функции:
;  - DISK_CLUSTER_READ
;  - CMP16
;  - COPCOUNT
;  - FAT_FIND_NEXT_CLUSTER
;  - STRCMP
; Оценка: длина - , время - 

FAT_FIND_BY_NAME:
FAT_FBN:
    mvi     a,$0B
    sta     SYSCELL_FBN11
fat_fbn_clust_process:
;Копируем кластер адреса LOCAL_CLUST_POINTER в буфер диска
;(SP+4) - начальный адрес строки, сод имя искомого файла
;(SP+2) - номер начального кластера директории, в которой ведем поиск
;(SP+0) - адрес возврата
    ldsi    $02
    lhlx
    push    h
    lhld    SYSCELL_DISKBUF_ADDR
    push    h
    call    DISK_CLUSTER_READ
;Подготовка переменной счетчика и указателя на дескрипторы файлов
    lhld    SYSCELL_DISKBUF_ADDR
    xchg
    mvi     c,$80
fat_fbn_cycle:
    push    b           ;счетчик в С
    push    d           ;указатель на дескриптор файла/субдиректории
;Копируем имя в строку SYSCELL_FBN11 (строка должна иметь впереди байт длины)
    lxi     b,$000B
    lxi     h,SYSCELL_FBN11P1
    call    COPCOUNT
;(SP+8) - начальный адрес строки, сод имя искомого файла
;(SP+6) - номер начального кластера директории, в которой ведем поиск
;(SP+4) - адрес возврата
;(SP+2) - счетчик в С
;(SP+0) - указатель на дескриптор файла/субдиректории
    ldsi    $08         ;DE <- SP+8
    lhlx
    lxi     d,SYSCELL_FBN11
    call    STRCMP ;Z==1 -> str1==str2
    pop     d           ;указатель на дескриптор файла/субдиректории
    pop     b           ;счетчик в С
    jz      fat_fbn_equal
;Строки не равны. Переходим к следующему дескриптору
    lxi     h,$0020
    dad     d
    xchg
    dcr     c
    jnz     fat_fbn_cycle
;В текущем кластере не найдено подходящих дескрипторов. Переход к след. кластеру
;(SP+4) - начальный адрес строки, сод имя искомого файла
;(SP+2) - номер начального кластера директории, в которой ведем поиск
;(SP+0) - адрес возврата
    ldsi    $02         ;DE <- SP+2
    lhlx
    push    d           ;SP+2
    push    h           ;(SP+4) LOCAL_CLUSTER_NUMBER
    call    FAT_FIND_NEXT_CLUSTER
    pop     h           ;NEXT_CLUSTER_NUMBER
    pop     d           ;SP+2
;Возврат, если следующего кластера нет
    jc      fat_fbn_return   ;DISK_ERROR_VECT    ;fat_fbn_return
    shlx                ;сохранить
    jmp     fat_fbn_clust_process
fat_fbn_equal:
;Строки равны. Передаем на вывод номер первого кластера файла/субдиректории
;DE - указатель на дескриптор файла/субдиректории
    push    d       ;сохранить указатель
    lxi     h,FAT_DESCR_FSTCLUST   ;смещение номера 1го кластера в дескрипторе
    dad     d
;BC <- Первый кластер файла или субдиректории
    mov     c,m
    inx     h
    mov     b,m
;A <- Status, SYSCELL_FAT_SF_STATUS <- Status
    pop     h
    push    h
    ldhi    FAT_DESCR_STATUS
    ldax    d
    sta     SYSCELL_FAT_SF_STATUS
;SYSCELL_FAT_SF_LEN <- Len
    pop     h
    ldhi    FAT_DESCR_SIZE
    lhlx
    shld    SYSCELL_FAT_SF_LEN_XLSB
    inx     d
    inx     d
    lhlx
    shld    SYSCELL_FAT_SF_LEN_MSB
    ora     a
fat_fbn_return:
;(SP+4) - начальный адрес строки, сод имя искомого файла
;(SP+2) - номер начального кластера директории, в которой ведем поиск
;(SP+0) - адрес возврата
    pop     h
    pop     d
    pop     d
    push    b
    push    psw
    pchl




; FAT_FBP - поиск указателя на файл по строке-пути
; Ввод:  (stack+2) - указатель на строку-путь
; Вывод: (stack+2)H - 0(все хорошо), 1(ошибка тропы), 2(ошибка диска)
; Используемые регистры: все
; Используемая память:
;  - массив DISKBUF (длины $1000)
;  - SYSCELL_FBN11 (строка 11 байт)
;  - SYSCELL_FAT_SF_STATUS (byte)
;  - SYSCELL_FAT_SF_LEN (uint32_t)
;  - SYSCELL_FBP11 (строка 11 байт)fat_fbn_return
; Используемые функции:
;  - DISK_CLUSTER_READ
;  - CMP16
;  - MFILL
;  - COPCOUNT
;  - FAT_FIND_NEXT_CLUSTER
; Оценка: длина - , время - 

FAT_FBP:
;(1) Установка начальной директории
    call    FAT_SPR
;(2) Считаем, сколько субдиректорий в пути
    pop     h
    xthl
    push    h
    mvi     b,$00
    mvi     a,$2F  ;'/'
    mov     c,m
    inx     h
fat_fbp_slcount_0:
    cmp     m
    jnz     fat_fbp_slcount_1
    inr     b
fat_fbp_slcount_1:
    inx     h
    dcr     c
    jnz     fat_fbp_slcount_0   
;B - число субдиректорий в пути
;(3) DE - PATHSTR_POINTER,  HL - STRBUF_POINTER
;    B - Local_Len,  C - PATHSTR_LEN,  (stack+1) - SUBDIRNUM
    pop     d
    ldax    d
    mov     c,a     ;PATHSTR_LEN
    inx     d       ;PATHSTR_POINTER
    push    b       ;SUBDIRNUM
    lxi     h,SYSCELL_FBP11
    mvi     m,$0B
;(4)--<Повторить SUBDIRNUM раз>-------------------------------------------------
    mov     a,b
    ora     a
    jz      fat_fbp_ilmsubdirnum
fat_fbp_m1:
;(4a) Local_len := 0, STRBUF_POINTER := STRBUF_ADDR+1, Очистка SYSCELL_FBP11
    mvi     b,$00
;STRBUF_POINTER := SYSCELL_FBP11+1
    lxi     h,SYSCELL_FBP11P1
;Очистка SYSCELL_FBP11
    push    b
    push    d
    push    h
    lxi     d,$000B
    mvi     a,$20
    call    MFILL
    pop     h
    pop     d
    pop     b
fat_fbp_m3:
;(4b) Читаем строку-путь
    ldax    d
    cpi     $2F  ;'/'
    jnz     fat_fbp_if_1
;(4ca) Если =='/':
;Если Local_len == 0, то ошибка
    mov     a,b
    ora     a
    jz      fat_fbp_path_error
;PATHSTR_POINTER+=1, PATHSTR_LEN-=1, Если PATHSTR_LEN==0, то ошибка
    inx     d
    dcr     c
    jz      fat_fbp_path_error
    jmp     fat_fbp_m2
fat_fbp_if_1:
;(4cb) Иначе
;SYSCELL_FBP11[STRBUF_POINTER] := PATHSTR[PATHSTR_POINTER]
    ldax    d
    mov     m,a
;STRBUF_POINTER += 1
    inx     h
;PATHSTR_POINTER+=1, PATHSTR_LEN-=1, Если PATHSTR_LEN==0, то ошибка
    inx     d
    dcr     c
    jz      fat_fbp_path_error
;Local_len += 1
    inr     b
    jmp     fat_fbp_m3
fat_fbp_m2:
;(4d) Спуск в субдиректорию (SYSCELL_FBP11)
    push    psw
    push    b
    push    d
    push    h
    lxi     h,SYSCELL_FBP11
    push    h
    lhld    SYSCELL_FAT_POINTER
    push    h
    call    FAT_FBN  ;Спуск в субдиректорию
    pop     psw
    pop     h
    jc      fat_fbp_finding_error
    ani     FAT_STATUS_SUBDIR_MASK
    jz      fat_fbp_finding_error
    shld    SYSCELL_FAT_POINTER
    pop     h
    pop     d
    pop     b
    pop     psw
;SUBDIRNUM-=1
    xthl
    dcr     h
    xthl
    jnz     fat_fbp_m1
fat_fbp_ilmsubdirnum:
;(5) Local_len:=0, STRBUF_POINTER:=STRBUF_ADDR+1, Очистка STRBUF
    mvi     b,$00
;STRBUF_POINTER := SYSCELL_FBP11+1
    lxi     h,SYSCELL_FBP11P1
;Очистка STRBUF
    push    b
    push    d
    push    h
    lxi     d,$000B
    mvi     a,$20
    call    MFILL
    pop     h
    pop     d
    pop     b
;Если PATHSTR_LEN==0, то ошибка
    mov     a,c
    ora     a
    jz      fat_fbp_path_error
fat_fbp_m4:
;(6) Читаем строку-путь
;SYSCELL_FBP11[STRBUF_POINTER] := PATHSTR[PATHSTR_POINTER]
    ldax    d
    cpi     $2E  ;'.'
    jnz     fat_fbp_if_4
;(7) Если =='.':
;Если Local_len == 0, то ошибка
    mov     a,b
    ora     a
    jz      fat_fbp_path_error
;STRBUF_POINTER := SYSCELL_FBP11+9
    lxi     h,SYSCELL_FBP11P9
;Local_len := 9
    mvi     b,$09
;PATHSTR_POINTER+=1, PATHSTR_LEN-=1, Если PATHSTR_LEN==0, то ошибка
    inx     d
    dcr     c
    mov     a,c
    ora     a
    jz      fat_fbp_path_error
    jmp     fat_fbp_m4
fat_fbp_if_4:
;(8) Иначе:
    mov     m,a
;Если Local_len == 8, то ошибка
    mov     a,b
    cpi     $08
    jz      fat_fbp_path_error
;Если Local_len > 11, то ошибка
    cpi     $0C
    jnc     fat_fbp_path_error
;Local_len += 1
    inr     b
;STRBUF_POINTER += 1
    inx     h
;PATHSTR_POINTER+=1, PATHSTR_LEN-=1
    inx     d
    dcr     c
;Переход fat_fbp_m4, если PATHSTR_LEN != 0
    jnz     fat_fbp_m4
;(9) Спуск в файл
    lxi     h,SYSCELL_FBP11
    push    h
    lhld    SYSCELL_FAT_POINTER
    push    h
    call    FAT_FIND_BY_NAME  ;Спуск в файл
    pop     psw
    pop     h
    jc      fat_fbp_finding_error_1
    ani     FAT_STATUS_SUBDIR_MASK
    jnz     fat_fbp_finding_error_1
    shld    SYSCELL_FAT_POINTER
;Восстановить баланс стека
    pop     h
;(10) Возврат
    pop     h
    mvi     a,$00
    push    psw
    pchl

fat_fbp_finding_error:
    pop     h
    pop     h
    pop     h
    pop     h
fat_fbp_finding_error_1:
    pop     h
    mvi     a,$02
    jmp     fat_fbp_com_error
fat_fbp_path_error:
    pop     h
    mvi     a,$01
fat_fbp_com_error:
    pop     h
    push    psw
    pchl
