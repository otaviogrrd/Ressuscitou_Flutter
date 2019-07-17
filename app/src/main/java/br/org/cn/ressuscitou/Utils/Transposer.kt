package br.org.cn.ressuscitou.Utils

class Transposer {
    internal var SHARPS = arrayOf("A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#")
    internal var FLATS = arrayOf("A", "Bb", "B", "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab")

    internal enum class TARGET {
        FLAT, SHARP
    }

    internal fun transpose(note: String, halfSteps: Int, target: TARGET?): String {
        var target = target
        if (target == null) {
            // By default we like flats
            target = TARGET.FLAT
        }

        var scale = FLATS
        if (target == TARGET.SHARP) {
            scale = SHARPS
        }

        var index = findIndex(scale, note)
        if (index < 0) return note // Not found, just return note


        var everythingelse = ""
        if (note.length > scale[index].length) {
            everythingelse = note.substring(scale[index].length)
        }


        index = index + halfSteps
        while (index < 0) {
            index += scale.size  // Make the index positive
        }
        index = index % scale.size
        return scale[index] + everythingelse
    }

    fun findIndex(scale: Array<String>, note: String): Int {
        val r = -1
        var root = note.substring(0, 1)
        if (note[1] == '#' || note[1] == 'b') {
            root = note.substring(0, 2)
        }
        for (i in scale.indices) {
            if (scale[i].equals(root, ignoreCase = true)) {
                // Match.
                return i
            }
        }
        return r
    }

//    @JvmStatic
//    fun main(args: Array<String>) {
//        val note = args[0]
//        val halfsteps = Integer.parseInt(args[1])
//        println(note + " transposed " + halfsteps + " halfsteps is " + transpose(note, halfsteps, TARGET.FLAT))
//    }
}