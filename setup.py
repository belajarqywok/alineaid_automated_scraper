from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules = cythonize([
        # Urls
        'urls.pyx',

        # Contents
        'contents.pyx'
    ]), include_dirs = []
)
