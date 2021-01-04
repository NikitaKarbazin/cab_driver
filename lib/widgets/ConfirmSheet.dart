import 'package:cab_driver/brand_colors.dart';
import 'package:cab_driver/widgets/TaxiButton.dart';
import 'package:cab_driver/widgets/TaxiOutlineButton.dart';
import 'package:flutter/material.dart';

class ConfirmSheet extends StatelessWidget {

  final String title;
  final String subtitle;
  final Function onPressed;

  ConfirmSheet({this.title, this.subtitle, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15.0,
            spreadRadius: 0.5,
            offset: Offset(
              0.7,
              0.7,
            ),
          )
        ]
      ),
      height: 220,
      child: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          children: <Widget>[

            SizedBox(height: 10,),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontFamily: 'Brand-Bold', color: BrandColors.colorText),
            ),

            SizedBox(height: 20,),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: BrandColors.colorTextLight),
            ),

            SizedBox(height: 24,),

            Row(
              children: <Widget>[

                Expanded(
                  child: Container(
                    child: TaxiOutlineButton(
                      title: 'НАЗАД',
                      color: BrandColors.colorLightGrayFair,
                      onPressed: (){
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),

                Expanded(
                  child: Container(
                    child: TaxiButton(
                      color: (title == 'ПРИСТУПИТЬ') ? BrandColors.colorBlue : BrandColors.colorOrange,
                      title: 'СОГЛАСЕН',
                      onPressed: onPressed,
                    ),
                  ),
                ),

              ],
            )

          ],
        ),
      ),
    );
  }
}
