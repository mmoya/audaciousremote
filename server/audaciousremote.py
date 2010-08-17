#!/usr/bin/python


import dbus
from jsonrpclib.SimpleJSONRPCServer import SimpleJSONRPCServer


class AudaciousProxy(object):
    def __init__(self):
        bus_name = 'org.atheme.audacious'

        self.bus = dbus.SessionBus()

        self.audacious_obj = self.bus.get_object(bus_name, '/org/atheme/audacious')
        self.audacious = dbus.Interface(self.audacious_obj,
                                        dbus_interface='org.atheme.audacious')

        self.player_obj = self.bus.get_object(bus_name, '/Player')
        self.player = dbus.Interface(self.player_obj,
                                     dbus_interface='org.freedesktop.MediaPlayer')

        self.tracklist_obj = self.bus.get_object(bus_name, '/TrackList')
        self.tracklist = dbus.Interface(self.tracklist_obj,
                                        dbus_interface='org.freedesktop.MediaPlayer')

    def next(self):
        self.player.Next()

    def pause(self):
        self.audacious.Pause()

    def play(self):
        self.audacious.Play()

    def prev(self):
        self.player.Prev()

    def stop(self):
        self.audacious.Stop()

    def time_get(self):
        return int(self.player.PositionGet())

    def time_set(self, value):
        self.player.PositionSet(value*1000)

    def volume_get(self):
        return int(self.player.VolumeGet())

    def volume_set(self, value):
        self.player.VolumeSet(value)

    def position_get(self):
        return int(self.audacious.Position())

    def position_set(self, value):
        self.audacious.Jump(value)

    def jump(self, value):
        self.position_set(value)

    def status(self):
        metadata = self.player.GetMetadata()
        result = dict()

        result['title'] = unicode(metadata['title'])
        result['artist'] = unicode(metadata['artist'])
        result['volume'] = self.volume_get()
        result['length'] = int(self.audacious.SongLength(self.position_get()))
        result['time'] = self.time_get() / 1000

        stopped = bool(self.audacious.Stopped())
        paused = bool(self.audacious.Paused())
        result['playing'] = not (paused or stopped)

        result['repeat'] = bool(self.audacious.Repeat())
        result['shuffle'] = bool(self.audacious.Shuffle())

        return result

    def playlist(self):
        playlist = list()

        for pos in range(self.audacious.Length()):
            metadata = self.tracklist.GetMetadata(pos)
            playlist.append({
                'artist': unicode(metadata['artist']),
                'title': unicode(metadata['title']),
            })

        return playlist


def main():
    server = SimpleJSONRPCServer(('', 8888))
    server.register_instance(AudaciousProxy())
    server.serve_forever()


if __name__ == '__main__':
    main()
