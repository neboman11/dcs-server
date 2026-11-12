#!/usr/bin/env python3
"""Generate Caucasus_Overlord_Test.miz: an OverlordBot test range.

Blue: E-3A "Overlord 1-1" (immortal) orbiting over Kutaisi; F/A-18C client slots
"Enfield 1" (4, parked hot at Kutaisi) and "Springfield 1" (2, airborne). Every Hornet has
COMM1 preset 1 = 251.000 AM, the OverlordBot frequency.
Red: two pairs of lowest-skill MiG-29A orbiting near Gudauta and Nalchik, weapons hold,
unlimited fuel, so they are safe bogey-dope targets.

Usage: uv run --with "pydcs @ git+https://github.com/pydcs/dcs@5ddcc63a2dcd661e16b14f7aa43219b93044855d" \
           missions/overlord_test.py [output.miz]
"""
import sys

import dcs
from dcs import task
from dcs.mission import StartType
from dcs.planes import E_3A, FA_18C_hornet, MiG_29A
from dcs.terrain import Caucasus
from dcs.unit import Skill

OVERLORD_MHZ = 251.0
KUTAISI_TOWER_MHZ = 134.0
FT = 0.3048


def western_callsign(group, name, number):
    for i, unit in enumerate(group.units, start=1):
        unit.callsign_dict = {1: number, 2: 1, 3: i, "name": f"{name}1{i}"}


def hornet_radios(group):
    # DCS also writes the group frequency into the first compatible preset (COMM1 ch1).
    group.frequency = OVERLORD_MHZ
    for unit in group.units:
        unit.set_radio_preset()
        unit.set_radio_channel_preset(1, 1, OVERLORD_MHZ)
        unit.set_radio_channel_preset(2, 1, KUTAISI_TOWER_MHZ)


def main(out):
    m = dcs.Mission(Caucasus())
    m.start_time = m.start_time.replace(hour=12, minute=0)
    m.weather.wind_at_ground.speed = 0
    m.weather.wind_at_2000.speed = 0
    m.weather.wind_at_8000.speed = 0
    m.weather.clouds_density = 0

    usa = m.country(dcs.countries.USA.name)
    russia = m.country(dcs.countries.Russia.name)
    kutaisi = m.terrain.airports["Kutaisi"]
    gudauta = m.terrain.airports["Gudauta"]
    nalchik = m.terrain.airports["Nalchik"]

    awacs = m.awacs_flight(usa, "Overlord", E_3A, None,
                           kutaisi.position.point_from_heading(180, 30000),
                           race_distance=60000, heading=90, altitude=int(30000 * FT),
                           speed=600, frequency=int(OVERLORD_MHZ))
    western_callsign(awacs, "Overlord", 1)
    awacs.points[0].tasks[0:0] = [task.SetImmortalCommand(), task.SetUnlimitedFuelCommand()]

    enfield = m.flight_group_from_airport(usa, "Enfield 1", FA_18C_hornet, kutaisi,
                                          start_type=StartType.Warm, group_size=4)
    springfield = m.flight_group_inflight(usa, "Springfield 1", FA_18C_hornet,
                                          kutaisi.position.point_from_heading(270, 20000),
                                          altitude=int(20000 * FT), speed=650, group_size=2)
    for group, (name, number) in ((enfield, ("Enfield", 1)), (springfield, ("Springfield", 2))):
        for unit in group.units:
            unit.skill = Skill.Client
        western_callsign(group, name, number)
        hornet_radios(group)
    springfield.add_waypoint(kutaisi.position.point_from_heading(0, 40000), int(20000 * FT), 650)

    for name, base, heading in (("Fulcrum 1", gudauta, 90), ("Fulcrum 2", nalchik, 270)):
        center = base.position.point_from_heading(heading, 15000)
        mig = m.flight_group_inflight(russia, name, MiG_29A, center, altitude=int(20000 * FT),
                                      speed=700, group_size=2)
        for i, unit in enumerate(mig.units, start=1):
            unit.skill = Skill.Average  # lowest AI skill DCS offers
            unit.callsign = int(name[-1]) * 100 + i * 10 + 1  # Russian-style numeric callsign
        # Orbit only: drop the default CAP engage task.
        mig.points[0].tasks = [
            task.SetUnlimitedFuelCommand(),
            task.OptROE(task.OptROE.Values.WeaponHold),
            task.OptReactOnThreat(task.OptReactOnThreat.Values.PassiveDefense),
            task.OrbitAction(altitude=int(20000 * FT), speed=700,
                             pattern=task.OrbitAction.OrbitPattern.Circle),
        ]

    m.set_description_text(
        "OverlordBot test range. Hornet COMM1 preset 1 is 251.000 AM (Overlord). "
        "Say: 'Overlord, Enfield one one, bogey dope' (use your flight/position callsign), "
        "'request picture', 'where is Sukhumi'. Red MiG-29s orbit near Gudauta and Nalchik "
        "with weapons hold.")
    m.save(out)
    print(out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "Caucasus_Overlord_Test.miz")
