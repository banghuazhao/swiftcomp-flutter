import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/home/model/layup_sequence_model.dart';
import 'package:swiftcomp/home/tools/explain.dart';

class LayupSequenceRow extends StatefulWidget {
  final LayupSequence layupSequence;
  final bool validate;

  const LayupSequenceRow({Key? key, required this.layupSequence, required this.validate})
      : super(key: key);

  @override
  _LayupSequenceRowState createState() => _LayupSequenceRowState();
}

class _LayupSequenceRowState extends State<LayupSequenceRow> {
  validateLayupSequence(List<double>? layups) {
    if (layups == null) {
      return "Wrong layup sequence";
    } else if (layups.length > 1000000) {
      return "Too many layers";
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(
                  "Layup Sequence",
                  style: Theme.of(context).textTheme.headline6,
                ),
                IconButton(
                  onPressed: () {
                    Dialog dialog = Dialog(
                      insetPadding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)), //this right here
                      child: Container(
                          padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
                          child: Explain.getExplain(ExplainType.layup_sequence, context)),
                    );
                    showDialog(context: context, builder: (BuildContext context) => dialog);
                  },
                  icon: Icon(
                    Icons.help_outline_rounded,
                    color: Colors.grey,
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: const OutlineInputBorder(),
                  labelText: "[xx/xx/xx/xx]msn",
                  errorText:
                      widget.validate ? validateLayupSequence(widget.layupSequence.layups) : null),
              onChanged: (value) {
                widget.layupSequence.value = value;
              },
            ),
          )
        ],
      ),
    );
  }
}
