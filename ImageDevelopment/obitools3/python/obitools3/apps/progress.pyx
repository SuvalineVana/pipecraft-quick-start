#cython: language_level=3

'''
Created on 27 mars 2016

@author: coissac
'''


from ..utils cimport str2bytes, bytes2str
from .config cimport getConfiguration 
import sys


cdef class ProgressBar:
    
    cdef clock_t clock(self):
        cdef clock_t t
        cdef timeval tp
        cdef clock_t s
        
        <void> gettimeofday(&tp,NULL)
        s = <clock_t> (<double> tp.tv_usec * 1.e-6 * <double> CLOCKS_PER_SEC)
        t = tp.tv_sec * CLOCKS_PER_SEC + s 
        
        return t


    def __init__(self,
                 off_t maxi,
                 dict  config={},
                 str head="",
                 double seconde=0.1,
                 cut=False):
        
        self.starttime = self.clock()
        self.lasttime  = self.starttime
        self.tickcount = <clock_t> (seconde * CLOCKS_PER_SEC)
        self.freq      = 1
        self.cycle     = 0
        self.arrow     = 0
        self.lastlog   = 0
        
        if not config:
            config=getConfiguration()
        
        self.ontty = sys.stderr.isatty()
        
        if (maxi<=0):
            maxi=1
            
        self.maxi  = maxi
        self.head  = head
        self.chead = self._head 
        self.cut   = cut
        
        self.logger=config[config["__root_config__"]]["logger"]
        self.wheel =  '|/-\\'
        self.spaces='          ' \
                    '          ' \
                    '          ' \
                    '          ' \
                    '          '
        self.diese ='##########' \
                    '##########' \
                    '##########' \
                    '##########' \
                    '##########'  
                          
             
    def __call__(self, object pos, bint force=False):
        cdef off_t    ipos
        cdef clock_t  elapsed
        cdef clock_t  newtime
        cdef clock_t  delta
        cdef clock_t  more 
        cdef double   percent 
        cdef tm remain
        cdef int days,hour,minu,sec
        cdef off_t fraction
        cdef int twentyth
        
        self.cycle+=1
    
        if self.cycle % self.freq == 0 or force:
            self.cycle=1
            newtime  = self.clock()
            delta         = newtime - self.lasttime
            self.lasttime = newtime
            elapsed       = newtime - self.starttime
#            print(" ",delta,elapsed,elapsed/CLOCKS_PER_SEC,self.tickcount)
            
            if   delta < self.tickcount / 5 :
                self.freq*=2
            elif delta > self.tickcount * 5 and self.freq>1:
                self.freq/=2
                
            
            if callable(pos):
                ipos=pos()
            else:
                ipos=pos
                
            if ipos==0:
                ipos=1                

            percent = <double>ipos/<double>self.maxi
            more = <time_t>((<double>elapsed / percent * (1. - percent))/CLOCKS_PER_SEC)
            <void>gmtime_r(&more, &remain)
            days  = remain.tm_yday 
            hour  = remain.tm_hour
            minu  = remain.tm_min
            sec   = remain.tm_sec
                
            if self.ontty:
                fraction=<int>(percent * 50.)
                self.arrow=(self.arrow+1) % 4
            
                if days:
                    <void>fprintf(stderr,b'\r%s %5.1f %% |%.*s%c%.*s] remain : %d days %02d:%02d:%02d\033[K',
                                    self.chead,
                                    percent*100,
                                    fraction,self.diese,
                                    self.wheel[self.arrow],
                                    50-fraction,self.spaces,
                                    days,hour,minu,sec)
                else:
                    <void>fprintf(stderr,b'\r%s %5.1f %% |%.*s%c%.*s] remain : %02d:%02d:%02d\033[K',
                                    self.chead,
                                    percent*100.,
                                    fraction,self.diese,
                                    self.wheel[self.arrow],
                                    50-fraction,self.spaces,
                                    hour,minu,sec)

            if self.cut:
                tenth = int(percent * 10)
                if tenth != self.lastlog:
                    
                    if self.ontty:
                        <void>fputs(b'\n',stderr)
                    
                    self.logger.info('%s %5.1f %% remain : %02d:%02d:%02d\033[K' % (
                                            bytes2str(self._head),
                                            percent*100.,
                                            hour,minu,sec))
                    self.lastlog=tenth
        else:
            self.cycle+=1


    property head:    
        def __get__(self):
            return self._head
        def __set__(self,str value):
            self._head=str2bytes(value)
            self.chead=self._head
