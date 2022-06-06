#include <stdio.h>
#include <time.h>
#include <sys/time.h>

int main(void) {
  struct timespec ts;
  struct tm t;

  clock_gettime(CLOCK_REALTIME, &ts);
  int n_sec = ts.tv_nsec / 1000;
  printf("%ld.%06d\n", ts.tv_sec, n_sec);

  return 0;
}
