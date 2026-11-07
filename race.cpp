#include <cstdio>
#include <thread>

int shared = 0;

void writer() { shared = 42; }
void reader() { std::printf("%d\n", shared); }

int main() {
    std::thread t1(writer);
    std::thread t2(reader);
    t1.join();
    t2.join();
}
