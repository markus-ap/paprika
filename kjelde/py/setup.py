from setuptools import setup

setup(
    name='paprika',
    version='0.0.1',
    py_modules=['paprika'],
    install_requires=[
        'Click',
    ],
    entry_points='''
        [console_scripts]
        paprika=paprika:tgs
    ''',
)