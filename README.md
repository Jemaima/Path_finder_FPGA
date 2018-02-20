# Path finder FPGA
Проект, выполненный в рамках курса Цифровая обработка сигналов.
Архитектурная особенность FPGA такова, что позволяет практически сколь угодно широко (определяется емкостью и характеристиками конкретного кристалла) распараллеливать работу алгоритмов, достигая за счет этого производительности, превышающей в десятки и сотни раз универсальные и сигнальные процессоры. Поэтому данное аппаратное решение отлично подходит для решения задач по обработке последовательностей изображений в режиме реального времени.

Идея проекта заключается в том, что при наведении камеры на изображение бинарного лабиринта, представленного на рисунке ниже, программа запускает агента сверху и проводит его через сложный маршрут.
<p align="center">
  <img src="http://priscree.ru/img/8b6cc225cf1eb8.jpg" width="500"/>
</p>

# Входные данные
Имеются некоторые ограничение к входному изображению.
Для начала работы алгоритма прохождения необходимо, чтобы все изображение лабиринта попадало в поле зрения камеры, так, чтобы начало и конец пути выходили за пределы кадра. Также важно, чтобы поворот изображения не должен превышать 10° 

# Инициализация первого кадра
Когда все требования выполнены, начинается инициализация параметров лабиринта. А именно, определяется стартовое положение агента, финиш и ширина дорожки.

<p align="center">
  <img src="http://priscree.ru/img/f9b9f39458971d.png" width="500"/>
</p>

# Принятие решения о следующем шаге
После определения стартового положения, алгоритм каждый кадр определяет следующее положение агента. Сканирование кадра окном 16х32 осуществляется с помощью FIFO. В момент, когда центр сканирующего окна попадает на текущее положение агента, определяется характер близлежащего участка (прямой отрезок, поворот, вблизи поворота), геометрические центры по 4 границам сканирующего окна, возможные направления движения, их которых выбирается то, которое не является обратным. После этого делается шаг в выбранном направлении.

[![test](http://priscree.ru/img/f9b9f39458971d.png)](https://yadi.sk/i/fP6RDXi_3Sc65Z)
