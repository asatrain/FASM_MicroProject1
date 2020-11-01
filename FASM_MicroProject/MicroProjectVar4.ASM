format PE console

entry start

include 'win32a.inc'

; Секция данных
section '.data' data readable writable

        ; Строка-формат вещественного числа
        floatFormat db '%lf', 0

        ; Текст ввода угла
        enterXText db 'Enter x in [%dpi, %dpi]: ', 0

        ; Текст результата подсчета с помощью рядов значения косинуса
        cosXResultText db 'Computed with mathematical series cos(%lf) = %lf', 10, 0

        ; Текст результата подсчета с помощью FCOS значения косинуса
        realCosXResultText db 'Computed with FCOS cos(%lf) = %lf', 10, 0

        ; Текст сообщения пользователю выхода за допустимые границы введенного угла
        xOutOfBoundsText db 'Entered x is not in allowed bounds...', 10, 0


        ; Процент точности вычисления, переведенный в коэффициент пропорциональности
        percentMultiplyer dq 0.001

        ; Коэффициент, задающий верхнюю границу (верхняя граница = PI * higherBoundPI)
        higherBoundPI dd 5

        ; Коэффициент, задающий нижнюю границу (нижняя граница = PI* lowerBoundPI)
        lowerBoundPI dd -5


        ; Текущая сумма ряда
        sum dq 0.0

        ; Предыдущий член ряда
        prevTerm dq 1.0

        ; Текущее значение итератора
        n dd 0

        ; Введенный угол в радианах
        x dq ?

        ; Временная переменная для хранения целых чисел
        intTmp dd ?

        ; Временная переменная для хранения вещественных чисел
        floatTmp dq ?

        NULL = 0

; Секция кода
section '.code' code readable executable

; Точка входа программы
start:
        call readX
        call countCosX
        call printCosX
        call printRealCosX

; Ожидание нажатия клавиши для завершения работы программы
finish:
        invoke getch
        push NULL
        invoke ExitProcess

; Проедура ввода угла
proc readX

        ; Предлоение пользователю ввода и чтение
        invoke printf, enterXText, [lowerBoundPI], [higherBoundPI]
        add esp, 12
        invoke scanf, floatFormat, x
        add esp, 8

        ; Проверка на выход за верхнюю границу
        FLDPI
        FIMUL [higherBoundPI]
        FLD [x]
        FCOMPP
        FSTSW ax
        SAHF
        ja xOutOfBounds

        ; Проверка на выход за нижнюю границу
        FLDPI
        FIMUL [lowerBoundPI]
        FLD [x]
        FCOMPP
        FSTSW ax
        SAHF
        jb xOutOfBounds

        ret

; Обработка выхода за границы
xOutOfBounds:
        invoke printf, xOutOfBoundsText
        add esp, 4
        jmp finish

endp

; Процедура подсчета с помощью степенного ряда значения косинуса
proc countCosX

        ; Инициализация сопроцессора
        FINIT

; Начало цикла последовательного суммирования членов ряда
sumLoop:
        ; ++n, sum += prevTerm
        inc [n]
        FLD [sum]
        FADD [prevTerm]
        FSTP [sum]

        ; prevTerm *= -1 * x * x / (2n) / (2n - 1)
        FLD [prevTerm]
        FCHS
        FMUL [x]
        FMUL [x]
        mov eax, [n]
        imul eax, 2
        mov [intTmp], eax
        FIDIV [intTmp]
        dec [intTmp]
        FIDIV [intTmp]
        FSTP [prevTerm]

        ; Если выполнено abs(prevTerm) <= percentMultiplyer * sum, выходим из цикла
        FLD [percentMultiplyer]
        FMUL [sum]
        FABS
        FLD [prevTerm]
        FABS
        FCOMPP
        FSTSW ax
        SAHF
        jbe sumLoopEnd

        ; Если же abs(prevTerm) > percentMultiplyer * sum, то
        ; запускаем следующую итерацию цикла
        jmp sumLoop
sumLoopEnd:
        ret

endp

; Процедура вывода подсчитанного значения косинуса
proc printCosX

        invoke printf, cosXResultText, dword[x], dword[x + 4],\
                                       dword[sum], dword[sum + 4]
        add esp, 20

        ret

endp

; Процедура вывода "точного" значения косинуса с помощью FCOS
proc printRealCosX

        FLD [x]
        FCOS
        FSTP [floatTmp]
        invoke printf, realCosXResultText, dword[x], dword[x + 4],\
                                           dword[floatTmp], dword[floatTmp + 4]
        add esp, 20

        ret

endp

; Секция импорта
section '.idata' import data readable

library kernel, 'kernel32.dll',\
        msvcrt, 'msvcrt.dll'

import kernel,\
       ExitProcess, 'ExitProcess'

import msvcrt,\
       printf, 'printf',\
       scanf, 'scanf',\
       getch, '_getch'