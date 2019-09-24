#!/usr/bin/env python3

import sys

from miflora.miflora_poller import MiFloraPoller, \
    MI_CONDUCTIVITY, MI_MOISTURE, MI_LIGHT, MI_TEMPERATURE, MI_BATTERY
from btlewrap.bluepy import BluepyBackend



for i in range(1, len(sys.argv)):
  mac = sys.argv[i]
  try:
    poller = MiFloraPoller(mac, BluepyBackend, 15)

    print("{}\tfirmware\t{}".format(mac, poller.firmware_version()))
    print("{}\tname\t{}".format(mac, poller.name()))
    print("{}\ttemperature\t{}".format(mac, poller.parameter_value(MI_TEMPERATURE)))
    print("{}\tmoisture\t{}".format(mac, poller.parameter_value(MI_MOISTURE)))
    print("{}\tlight\t{}".format(mac, poller.parameter_value(MI_LIGHT)))
    print("{}\tconductivity\t{}".format(mac, poller.parameter_value(MI_CONDUCTIVITY)))
    print("{}\tbattery\t{}".format(mac, poller.parameter_value(MI_BATTERY)))

  except:
    print("{}\terror\t1".format(mac))

exit(0)
