from ruamel.yaml.comments import CommentedSeq, CommentedMap
from ruamel.yaml import dump, RoundTripDumper
from copy import deepcopy
import sys


if sys.version_info[0] == 3:
    unicode = str


class YAMLPointer(object):
    """
    A sequence of indexes/keys that look up a specific chunk of a YAML document.

    A YAML pointer can point to a key, value, item in a sequence or part of a string
    in a value or item.
    """

    def __init__(self):
        self._indices = []

    @property
    def last_index(self):
        assert self.is_index()
        return self._indices[-1][1]

    @property
    def last_val(self):
        assert self.is_val()
        return self._indices[-1][1]

    @property
    def last_strictkey(self):
        assert self.is_key() or self.is_val()
        return self._indices[-1][1][1]

    @property
    def last_regularkey(self):
        assert self.is_key() or self.is_val()
        return self._indices[-1][1][0]

    def val(self, regularkey, strictkey):
        assert isinstance(regularkey, (str, unicode)), type(regularkey)
        assert isinstance(strictkey, (str, unicode)), type(strictkey)
        new_location = deepcopy(self)
        new_location._indices.append(("val", (regularkey, strictkey)))
        return new_location

    def is_val(self):
        return self._indices[-1][0] == "val"

    def key(self, regularkey, strictkey):
        assert isinstance(regularkey, (str, unicode)), type(regularkey)
        assert isinstance(strictkey, (str, unicode)), type(strictkey)
        new_location = deepcopy(self)
        new_location._indices.append(("key", (regularkey, strictkey)))
        return new_location

    def is_key(self):
        return self._indices[-1][0] == "key"

    def index(self, index):
        new_location = deepcopy(self)
        new_location._indices.append(("index", index))
        return new_location

    def is_index(self):
        return self._indices[-1][0] == "index"

    def textslice(self, start, end):
        new_location = deepcopy(self)
        new_location._indices.append(("textslice", (start, end)))
        return new_location

    def is_textslice(self):
        return self._indices[-1][0] == "textslice"

    def parent(self):
        new_location = deepcopy(self)
        new_location._indices = new_location._indices[:-1]
        return new_location

    def make_child_of(self, pointer):
        new_indices = deepcopy(pointer._indices)
        new_indices.extend(self._indices)

    def _slice_segment(self, indices, segment, include_selected):
        slicedpart = deepcopy(segment)

        if len(indices) == 0 and not include_selected:
            slicedpart = None
        else:
            if len(indices) > 0:
                if indices[0][0] in ("val", "key"):
                    index = indices[0][1][0]
                else:
                    index = indices[0][1]
                start_popping = False

                if isinstance(segment, CommentedMap):
                    for key in segment.keys():
                        if start_popping:
                            slicedpart.pop(key)

                        if index == key:
                            start_popping = True

                            if isinstance(segment[index], (CommentedSeq, CommentedMap)):
                                slicedpart[index] = self._slice_segment(
                                    indices[1:],
                                    segment[index],
                                    include_selected=include_selected,
                                )

                            if not include_selected and len(indices) == 1:
                                slicedpart.pop(key)

                if isinstance(segment, CommentedSeq):
                    for i, value in enumerate(segment):
                        if start_popping:
                            del slicedpart[-1]

                        if i == index:
                            start_popping = True

                            if isinstance(segment[index], (CommentedSeq, CommentedMap)):
                                slicedpart[index] = self._slice_segment(
                                    indices[1:],
                                    segment[index],
                                    include_selected=include_selected,
                                )

                            if not include_selected and len(indices) == 1:
                                slicedpart.pop(index)

        return slicedpart

    def start_line(self, document):
        slicedpart = self._slice_segment(
            self._indices, document, include_selected=False
        )

        if slicedpart is None or slicedpart == {} or slicedpart == []:
            return 1
        else:
            return (
                len(dump(slicedpart, Dumper=RoundTripDumper).rstrip().split("\n")) + 1
            )

    def end_line(self, document):
        slicedpart = self._slice_segment(self._indices, document, include_selected=True)
        return len(dump(slicedpart, Dumper=RoundTripDumper).rstrip().split("\n"))

    def lines(self, document):
        return "\n".join(
            dump(document, Dumper=RoundTripDumper).split("\n")[
                self.start_line(document) - 1 : self.end_line(document)
            ]
        )

    def lines_before(self, document, how_many):
        return "\n".join(
            dump(document, Dumper=RoundTripDumper).split("\n")[
                self.start_line(document) - 1 - how_many : self.start_line(document) - 1
            ]
        )

    def lines_after(self, document, how_many):
        return "\n".join(
            dump(document, Dumper=RoundTripDumper).split("\n")[
                self.end_line(document) : self.end_line(document) + how_many
            ]
        )

    def get(self, document, strictdoc=False):
        segment = document
        for index_type, index in self._indices:
            if index_type == "val":
                segment = segment[index[1] if strictdoc else index[0]]
            elif index_type == "index":
                segment = segment[index]
            elif index_type == "textslice":
                segment = segment[index[0] : index[1]]
            elif index_type == "key":
                segment = index[1] if strictdoc else index[0]
            else:
                raise RuntimeError("Invalid state")
        return segment

    def __repr__(self):
        return "<YAMLPointer: {0}>".format(self._indices)
