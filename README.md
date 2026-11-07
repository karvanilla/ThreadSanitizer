# ThreadSanitizer

ThreadSanitizer обнаруживает гонки данных в многопоточной программе.

На примере двух потоков показаны инструментация, неправильная и правильная реализация, а также принцип обнаружения ошибки.

## Материалы

- `race.cpp` — программа с гонкой данных.
- `race.ll` — инструментированный LLVM IR.
- `tsan.log` — диагностический отчёт TSan.
- `Tsan(1,2 сцены).py` — создание анимации первых двух сцен.
- Схемы, видео(пока что 2 сцены) и `ts.docx` — иллюстрации и объяснение работы анализатора.

## Создание видео


```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install numpy pillow opencv-python-headless imageio-ffmpeg
python "Tsan(1,2 сцены).py"
```

Видео `ThreadSanitizer_full.mp4`

## Запуск примера с TSan

```bash
clang++ -std=c++17 -g -O1 -fsanitize=thread -pthread race.cpp -o race
./race
```

Пример содержит ошибку намеренно. TSan обнаруживает её и выводит предупреждение `WARNING: ThreadSanitizer: data race`.
