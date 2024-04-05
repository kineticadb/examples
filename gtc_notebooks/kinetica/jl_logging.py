##
# Copyright (c) 2024, Chad Juliano, Kinetica DB Inc.
##

from typing import TYPE_CHECKING, Any, TypeVar, Optional
from logging import Logger, Handler
import logging
import colorlog

_T = TypeVar("_T")

# https://pypi.org/project/colorlog/
# https://docs.python.org/3/library/logging.html#logrecord-attributes

def color_log(code: str, color: str = 'log_color', fmt: str = "s") -> str:
    return f"%({color})s%({code}){fmt}%(reset)s"

# This controls the columns in the log output. There is one item per column.
LOG_COLS = [
    '{}'.format(color_log('levelname', 'log_color', '-7s')),
    #'{}'.format(color_log('asctime', 'white')),
    '[{}]'.format(color_log('name', 'light_blue')),
    color_log('message', 'white')
]

CLASS_LEVEL = logging.INFO
HANDLER = None

def setup_logging(rootlevel: int = logging.WARNING,
                  classlevel: int = logging.INFO,
                  no_color: bool = False) -> Handler:
    """
    Initialize color logging.

    Parameters:
        rootlevel:
            Log level for root logger:

        classlevel:
            Log level for classes using LoggingMixin
    """
    global CLASS_LEVEL
    CLASS_LEVEL = classlevel

    global HANDLER
    if(not HANDLER):
        HANDLER = colorlog.StreamHandler()
        formatter = colorlog.ColoredFormatter(fmt=" ".join(LOG_COLS),
                                            no_color=no_color,
                                            datefmt='%Y-%m-%d %H:%M:%S')
        HANDLER.setFormatter(formatter)

    rootLogger = logging.getLogger("root")

    if HANDLER not in rootLogger.handlers:
        rootLogger.addHandler(HANDLER)
        rootLogger.setLevel(logging.INFO)
        rootLogger.info("Logging initialized (root={}, class={})"
                   .format(logging._levelToName[rootlevel],
                           logging._levelToName[classlevel]))

    rootLogger.setLevel(rootlevel)
    return HANDLER


class LoggingMixin:
    """
    Convenience super-class to have a logger configured with the class name.
    Copied from: https://github.com/apache/airflow/blob/main/airflow/utils/log/logging_mixin.py
    """

    _log: Optional[logging.Logger] = None

    def __init__(self, context=None):
        self._set_context(context)

    @staticmethod
    def _get_log(obj: Any, clazz: type[_T]) -> Logger:
        if obj._log is None:
            #obj._log = logging.getLogger(f"{clazz.__module__}.{clazz.__name__}")
            obj._log = logging.getLogger(f"{clazz.__name__}")
            obj._log.setLevel(CLASS_LEVEL)
        return obj._log

    @classmethod
    def logger(cls) -> Logger:
        """Returns a logger."""
        return LoggingMixin._get_log(cls, cls)

    @property
    def log(self) -> Logger:
        """Returns a logger."""
        return LoggingMixin._get_log(self, self.__class__)