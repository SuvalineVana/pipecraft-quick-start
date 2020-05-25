import glob
import os
import sys
import re
import subprocess

from distutils import log
from distutils.core import setup
    
from distutils.core import Extension
from distutils.sysconfig import get_python_lib

import os.path
from distutils import log
from distutils.extension import Extension

from distutils.dist import Distribution as ori_Distribution

from python.obitools3.version import version


class Distribution(ori_Distribution):
    
    def __init__(self,attrs=None):
        self.cobitools3=attrs['cobitools3']
        
        ori_Distribution.__init__(self, attrs)
        
        self.global_options.insert(0,('cobitools3', None, "intall location of the C library"
                                     ))

from distutils.command.build import build as build_ori
from distutils.core import Command


class build_clib(Command):
    user_options=[]
    
    def initialize_options(self):
        self.clib_dir=self.distribution.cobitools3
    
    def finalize_options(self):
        if self.clib_dir is None:
            self.clib_dir=get_python_lib()
    
    def run(self):
        log.info("Build the build/cobject directory")
        try:
            os.mkdir("build")
        except OSError:
            pass
        try:
            os.mkdir("build/cobject")
        except OSError:
            pass
        
        oldwd = os.getcwd()
        os.chdir("build/cobject")
        install_clibdir_option="-DPYTHONLIB:STRING='%s'" % self.clib_dir
        log.info("Run CMake")
        subprocess.call(['cmake', install_clibdir_option, '../../src'])
        log.info("Compile the shared C library")
        subprocess.call(['make','install'])   # temporary fix but should be in src
        os.chdir(oldwd)


class build(build_ori):
    def run(self):
        self.run_command("build_clib")
        build_ori.run(self)


sys.path.append(os.path.abspath("python"))


def findPackage(root,base=None):
    modules=[]
    if base is None:
        base=[]
    for module in (os.path.basename(os.path.dirname(x)) 
                   for x in glob.glob(os.path.join(root,'*','__init__.py'))):
        modules.append('.'.join(base+[module]))
        modules.extend(findPackage(os.path.join(root,module),base+[module]))
    return modules
  

PACKAGE     = "OBITools3"
VERSION     = version
AUTHOR      = 'Celine Mercier'
EMAIL       = 'celine.mercier@metabarcoding.org'
URL         = "http://metabarcoding.org/obitools3"
LICENSE     = "CeCILL-V2"
DESCRIPTION = "Tools and library for DNA metabarcoding",
PYTHONMIN   = '3.5'

SRC       = 'python'
CSRC      = 'src'

REQUIRES  = ['Cython>=0.24',
             'Sphinx>=1.2.0',
             'ipython>=3.0.0',
             'breathe>=4.0.0'
            ]

os.environ['CFLAGS'] = '-O3 -w -I "src" -I "src/libecoPCR" -I "src/libjson"'


from Cython.Build import cythonize

cython_src  = [x for x in glob.iglob('python/obitools3/**/*.pyx', 
                                     recursive=True
                                    )
              ]
      

cython_ext  = [Extension('.'.join([os.path.dirname(x).replace("python/",""),
                                   os.path.splitext(os.path.basename(x))[0]]).replace('/','.'),
                         [x],
                         library_dirs=[get_python_lib()],
                         include_dirs=["src","src/libecoPCR","src/libjson"],
                         libraries=["cobitools3"],
                         runtime_library_dirs=[get_python_lib()],
                         extra_compile_args=['-msse2',
                                          '-w',
                                          '-fPIC'
                                         ],
                         extra_link_args=["-Wl,-rpath,"+get_python_lib(), 
                                          "-L"+get_python_lib()
                                         ]
                        )
                for x in cython_src
              ]              

xx = cythonize(cython_ext,
               language_level=3,
               annotate=True,
               build_dir="build")

classifiers=['Development Status :: 4 - Beta',
             'Environment :: Console',
             'Intended Audience :: Science/Research',
             'License :: Other/Proprietary License',
             'Operating System :: Unix',
             'Programming Language :: Python :: 3',
             'Programming Language :: C',
             'Topic :: Scientific/Engineering :: Bio-Informatics',
             'Topic :: Utilities',
             ]

setup(name=PACKAGE,
      description=DESCRIPTION,
      classifiers=classifiers,
      version=VERSION,
      author=AUTHOR,
      author_email=EMAIL,
      license=LICENSE,
      url=URL,
      ext_modules=xx,
      distclass=Distribution,
      cmdclass={'build': build,
                'build_clib': build_clib},
      cobitools3=get_python_lib(),
      packages = findPackage('python'),
      package_dir = {"" : "python"},
      scripts = ['scripts/obi']
)

