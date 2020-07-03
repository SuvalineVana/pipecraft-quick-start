#cython: language_level=3

cpdef str setRootConfigName(str rootname)
cpdef str getRootConfigName()

cdef dict buildDefaultConfiguration(str root_config_name,
                                    dict  config)

cpdef dict getConfiguration(str root_config_name=?,
                                    dict  config=?)
