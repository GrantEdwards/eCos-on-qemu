#include <stdio.h>
#include <stdlib.h>
#include <network.h>
#include <cyg/infra/diag.h>

#ifndef CYGPKG_LIBC_STDIO
#define perror(s) diag_printf(#s ": %s\n", strerror(errno))
#endif


#define STACK_SIZE (8* CYGNUM_HAL_STACK_SIZE_TYPICAL + 0x1000)
static char net_test_stack[STACK_SIZE];
static cyg_thread net_test_thread_data;
static cyg_handle_t net_test_thread_handle;

#define NUM_THREADS 8
static struct
{
  char stack[STACK_SIZE];
  cyg_thread thread_data;
  cyg_handle_t handle;
} echo_thread[NUM_THREADS];


void pexit(char *s)
{
  perror(s);
  while (1)
    cyg_thread_delay(100);
}

ssize_t sendall(int s, const void *buf, size_t len, int flags)
{
  size_t n=0,r=0;
  while (n < len)
    {
      r = send(s,(char*)buf+n,len-n,flags);
      if (r <= 0)
        break;
      n += r;
    }
  return r;
}


#define log() diag_printf("%s %d\n",__FILE__,__LINE__)

#define Error(s) do {diag_printf("%s: %s\n",s,strerror(errno)); goto error;} while (0)

static void echo(cyg_addrword_t param)
{
  int sockfd = -1, newfd = -1, yes = 1;
  cyg_uint8 buf[1024];
  unsigned port = 8000 + (unsigned)param;
  struct sockaddr_in my_addr, their_addr;

  diag_printf("thread running for port %d buffer=%p\n",port,buf);

  while (1)
    {
      if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
        Error("socket()");
      
      if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) == -1)
        Error("setsockopt()");
      
      my_addr.sin_family = AF_INET;
      my_addr.sin_port = htons(port);
      my_addr.sin_addr.s_addr = INADDR_ANY;
      memset(&(my_addr.sin_zero), '\0', 8);
      diag_printf("Server-Using %s and port %d...\n", inet_ntoa(my_addr.sin_addr), port);
      
      if(bind(sockfd, (struct sockaddr *)&my_addr, sizeof(struct sockaddr)) == -1)
        Error("bind()");
      
      if(listen(sockfd, 1) == -1)
        Error("listen()");
      
      while (1)
        {
          unsigned sin_size = sizeof(struct sockaddr_in);
          
          diag_printf("Waiting for connection on port %d\n",port);
          
          if((newfd = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size)) == -1)
            Error("accept()");
          
          diag_printf("Connection to port %d from %s\n", port, inet_ntoa(their_addr.sin_addr));
          
          while (1)
            {
              int n;
              if ((n = recv(newfd,buf, sizeof buf,0)) <= 0)
                {
                  diag_printf("recv()==%d on port %d, closing connection\n",n,port);
                  break;
                }
              if ((n = sendall(newfd,buf,n,0)) <= 0)
                {
                  diag_printf("sendall()==%d on port %d, closing connection\n",n,port);
                  break;
                }
            }
          
          if (newfd >= 0)
            {
              close(newfd);
              newfd = -1;
            }
          
        }

    error:

      if (sockfd >= 0)
        {
          close(sockfd);
          sockfd = -1;
        }
      if (newfd >= 0)
        {
          close(newfd);
          newfd = -1;
        }
      cyg_thread_delay(100);
    }
}

void net_test(cyg_addrword_t param)
{
  int i;
  diag_printf("Start SERVER test\n");
  init_all_network_interfaces();
  while (!eth0_up)
    {
      diag_printf("Interface eth0 isn't up!\n");
      cyg_thread_delay(100);
    }

  for (i=0; i<NUM_THREADS; ++i)
    {
      cyg_thread_create(8,         // Priority
                        echo,      // entry
                        i,         // entry parameter
                        "echo",     // Name
                        &echo_thread[i].stack,  // Stack
                        STACK_SIZE, // Size
                        &echo_thread[i].handle,     // Handle
                        &echo_thread[i].thread_data        // Thread data structure
                        );
      cyg_thread_resume(echo_thread[i].handle);     // Start it
    }
  while (1)
    cyg_thread_delay(100);
}

void cyg_start(void)
{
  // Create a main thread, so we can run the scheduler and have time 'pass'
  cyg_thread_create(10,         // Priority - just a number
                    net_test,   // entry
                    0,          // entry parameter
                    "Network test",     // Name
                    &net_test_stack[0],  // Stack
                    STACK_SIZE, // Size
                    &net_test_thread_handle,     // Handle
                    &net_test_thread_data        // Thread data structure
    );
  cyg_thread_resume(net_test_thread_handle);     // Start it
  cyg_scheduler_start();
}

