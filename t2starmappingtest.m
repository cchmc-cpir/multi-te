import mapping.t2starmap

t2starmap([128, 128, 128], 65, uigetfile({'*.*', 'All Files (*.*)'}, 'Multiselect', 'on'), ...
    './sample', 'now', 3, 0, 'expiration');
