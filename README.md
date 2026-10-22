# Farmer Crop Expense Record

Student ID: 24PA1A05H7

A Flutter app for farmers to track crop-wise expenses, expected income and profit/loss.

## Features
- Dashboard for total expenses, expected income, net profit/loss, and number of crop records
- Add crop, season, land area, expense breakdown, expected yield and selling price
- Automatic cost, income and profit/loss calculations
- Local saving with SharedPreferences
- View recent records and delete records
- Input validation and rupee formatting

## Run
1. Install Flutter SDK and Android Studio or VS Code with Flutter support.
2. Clone this repository and enter the folder.
3. Run `flutter pub get` then `flutter run`.

This repository includes the Flutter app source and package configuration. To generate Android/iOS platform scaffolding, run `flutter create .` inside the project folder.

## Formulae
- Total expenses = seeds + fertilizer + pesticides + labour + irrigation + machinery + other costs
- Expected income = expected yield (quintals) × selling price per quintal
- Profit/loss = expected income − total expenses
