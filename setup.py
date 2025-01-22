from setuptools import setup, find_packages
import os

def read(fname):
    with open(os.path.join(os.path.dirname(__file__), fname)) as f:
        return f.read()

setup(
    name="ssh4gh",
    version="1.0.0",
    author="heartonbit",
    author_email="minkyu.shim@gmail.com",
    description="GitHub SSH Key Manager",
    long_description=read('README.md'),
    long_description_content_type="text/markdown",
    url="https://github.com/heartonbit/ssh4gh",
    packages=find_packages(),
    package_data={
        'ssh4gh': ['scripts/ssh4gh.sh'],
    },
    entry_points={
        'console_scripts': [
            'ssh4gh=ssh4gh.cli:main',
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
    ],
    python_requires='>=3.6',
    install_requires=[
        'click>=7.0',
    ],
) 