/* this is a simple hello world program */
#include <cyg/infra/diag.h>
#include <network.h>
int main(void)
{
  init_all_network_interfaces();
  diag_printf("Hello, eCos world!\n");
  while (1)
    {
      cyg_thread_delay(50); // 500ms
      diag_printf(".");
    }
}
