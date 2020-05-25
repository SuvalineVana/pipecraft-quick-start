#cython: language_level=3

cdef extern from "stdio.h":
    struct FILE
    int fprintf(FILE *stream, char *format, ...)
    int fputs(char *string, FILE *stream)
    FILE* stderr
    ctypedef unsigned int off_t "unsigned long long"
    
cdef extern from "unistd.h":
    int fsync(int fd);

cdef extern from "time.h":
    struct tm :
        int tm_yday 
        int tm_hour
        int tm_min
        int tm_sec

    enum: CLOCKS_PER_SEC
    
    ctypedef int time_t
    ctypedef int clock_t
    ctypedef int suseconds_t
    
    struct timeval:
        time_t      tv_sec     #  seconds */
        suseconds_t tv_usec    #  microseconds */


    struct timezone :
        int tz_minuteswest;    # minutes west of Greenwich
        int tz_dsttime;        # type of DST correction 

        
    int gettimeofday(timeval *tv, timezone *tz)


    tm *gmtime_r(time_t *clock, tm *result)
    time_t time(time_t *tloc)
    clock_t clock()

cdef class ProgressBar:
    cdef off_t   maxi
    cdef clock_t starttime
    cdef clock_t lasttime
    cdef clock_t tickcount
    cdef int freq
    cdef int cycle
    cdef int arrow
    cdef int lastlog
    cdef bint ontty
    cdef int fd
    cdef bint cut
    
    cdef bytes _head
    cdef char *chead
    
    cdef object logger

    cdef char  *wheel
    cdef char  *spaces
    cdef char*  diese 
    
    cdef clock_t clock(self)
