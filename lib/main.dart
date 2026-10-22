import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FarmerExpenseApp());

const farmGreen = Color(0xFF176B45);
const paleGreen = Color(0xFFEAF5EE);

String rupees(num n) => '₹${n.toStringAsFixed(2)}';

class FarmerExpenseApp extends StatelessWidget {
  const FarmerExpenseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Farmer Crop Expense Record',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: farmGreen),
          scaffoldBackgroundColor: const Color(0xFFF6F8F5),
          appBarTheme: const AppBarTheme(backgroundColor: farmGreen, foregroundColor: Colors.white),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        home: const ExpenseHomePage(),
      );
}

class CropRecord {
  final String id, crop, season;
  final double acres, seeds, fertilizer, pesticides, labour, irrigation, machinery, other, yieldQ, price;
  final DateTime date;
  const CropRecord({required this.id, required this.crop, required this.season, required this.acres,
    required this.seeds, required this.fertilizer, required this.pesticides, required this.labour,
    required this.irrigation, required this.machinery, required this.other, required this.yieldQ,
    required this.price, required this.date});
  double get expense => seeds + fertilizer + pesticides + labour + irrigation + machinery + other;
  double get income => yieldQ * price;
  double get profit => income - expense;
  Map<String, dynamic> toJson() => {'id':id,'crop':crop,'season':season,'acres':acres,'seeds':seeds,
    'fertilizer':fertilizer,'pesticides':pesticides,'labour':labour,'irrigation':irrigation,
    'machinery':machinery,'other':other,'yieldQ':yieldQ,'price':price,'date':date.toIso8601String()};
  factory CropRecord.fromJson(Map<String, dynamic> j) => CropRecord(
    id:j['id'], crop:j['crop'], season:j['season'] ?? 'Other',
    acres:(j['acres'] as num).toDouble(), seeds:(j['seeds'] as num).toDouble(),
    fertilizer:(j['fertilizer'] as num).toDouble(), pesticides:(j['pesticides'] as num).toDouble(),
    labour:(j['labour'] as num).toDouble(), irrigation:(j['irrigation'] as num).toDouble(),
    machinery:(j['machinery'] as num).toDouble(), other:(j['other'] as num).toDouble(),
    yieldQ:(j['yieldQ'] as num).toDouble(), price:(j['price'] as num).toDouble(),
    date:DateTime.tryParse(j['date'] ?? '') ?? DateTime.now());
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});
  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}
class _ExpenseHomePageState extends State<ExpenseHomePage> {
  List<CropRecord> records = [];
  bool loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try {
      final raw = p.getString('crop_records');
      if (raw != null) records = (jsonDecode(raw) as List)
          .map((e) => CropRecord.fromJson(Map<String, dynamic>.from(e))).toList();
      records.sort((a,b) => b.date.compareTo(a.date));
    } catch (_) { records = []; }
    if (mounted) setState(() => loading = false);
  }
  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('crop_records', jsonEncode(records.map((r) => r.toJson()).toList()));
  }
  double get expenses => records.fold(0, (s,r) => s+r.expense);
  double get income => records.fold(0, (s,r) => s+r.income);
  Future<void> _add() async {
    final r = await Navigator.push<CropRecord>(context, MaterialPageRoute(builder: (_) => const AddCropPage()));
    if (r != null) { setState(() => records.insert(0,r)); await _save(); }
  }
  Future<void> _delete(CropRecord r) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete record?'), content: Text('Delete the ${r.crop} record?'),
      actions: [TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Delete'))]));
    if (ok == true) { setState(() => records.removeWhere((x)=>x.id==r.id)); await _save(); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Farmer Expense Book', style: TextStyle(fontWeight: FontWeight.bold)),
      Text('Crop-wise cost and profit tracker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal))])),
    floatingActionButton: FloatingActionButton.extended(onPressed:_add, backgroundColor:farmGreen,
      foregroundColor:Colors.white, icon:const Icon(Icons.add), label:const Text('Add crop record')),
    body: loading ? const Center(child:CircularProgressIndicator()) : RefreshIndicator(
      onRefresh:_load, child:ListView(padding:const EdgeInsets.all(16), children:[
        Container(padding:const EdgeInsets.all(20), decoration:BoxDecoration(
          gradient:const LinearGradient(colors:[farmGreen,Color(0xFF329764)]),
          borderRadius:BorderRadius.circular(22)), child:const Row(children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Plan better. Grow smarter.',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
              SizedBox(height:8),Text('Know where every rupee goes.',style:TextStyle(color:Colors.white70))])),
            Icon(Icons.agriculture,size:54,color:Colors.white)])),
        const SizedBox(height:20),
        const Text('Farm overview',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,
          mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.45,children:[
            SummaryTile(title:'Total expenses',value:rupees(expenses),icon:Icons.payments,color:Colors.deepOrange),
            SummaryTile(title:'Expected income',value:rupees(income),icon:Icons.trending_up,color:farmGreen),
            SummaryTile(title:income>=expenses?'Net profit':'Net loss',value:rupees((income-expenses).abs()),icon:Icons.savings,color:income>=expenses?farmGreen:Colors.red),
            SummaryTile(title:'Crop records',value:'${records.length}',icon:Icons.receipt_long,color:Colors.blue)]),
        const SizedBox(height:22),
        const Text('Crop records',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        const SizedBox(height:10),
        if(records.isEmpty) Container(padding:const EdgeInsets.all(26),
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),
          child:const Column(children:[Icon(Icons.spa_outlined,size:48,color:farmGreen),SizedBox(height:10),
            Text('No records yet',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
            SizedBox(height:5),Text('Tap Add crop record to enter your first crop.',textAlign:TextAlign.center)]))
        else ...records.map((r)=>Card(color:Colors.white,elevation:0,margin:const EdgeInsets.only(bottom:10),
          child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
            Row(children:[const Icon(Icons.grass,color:farmGreen,size:30),const SizedBox(width:10),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(r.crop,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
                Text('${r.season} • ${r.acres} acres • ${r.date.day}/${r.date.month}/${r.date.year}',
                  style:const TextStyle(color:Colors.black54,fontSize:12))])),
              IconButton(onPressed:()=>_delete(r),icon:const Icon(Icons.delete_outline,color:Colors.red))]),
            const Divider(),Row(children:[
              Expanded(child:Metric(label:'Expenses',value:rupees(r.expense),color:Colors.deepOrange)),
              Expanded(child:Metric(label:'Income',value:rupees(r.income),color:farmGreen)),
              Expanded(child:Metric(label:r.profit>=0?'Profit':'Loss',value:rupees(r.profit.abs()),color:r.profit>=0?farmGreen:Colors.red))])])))),
        const SizedBox(height:80),
        const Text('Student ID: 24PA1A05H7',textAlign:TextAlign.center,style:TextStyle(color:Colors.black45,fontSize:12))
      ])),
  );
}

class SummaryTile extends StatelessWidget {
  final String title,value; final IconData icon; final Color color;
  const SummaryTile({super.key,required this.title,required this.value,required this.icon,required this.color});
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),
      border:Border.all(color:const Color(0xFFE5EBE5))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,
      children:[Icon(icon,color:color,size:25),Text(value,maxLines:1,overflow:TextOverflow.ellipsis,
        style:TextStyle(fontWeight:FontWeight.bold,fontSize:17,color:color)),
        Text(title,style:const TextStyle(color:Colors.black54,fontSize:12))]));
}
class Metric extends StatelessWidget {
  final String label,value; final Color color;
  const Metric({super.key,required this.label,required this.value,required this.color});
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(label,style:const TextStyle(fontSize:11,color:Colors.black54)),
    const SizedBox(height:4),Text(value,maxLines:1,overflow:TextOverflow.ellipsis,
      style:TextStyle(fontSize:12,fontWeight:FontWeight.bold,color:color))]);
}

class AddCropPage extends StatefulWidget {
  const AddCropPage({super.key});
  @override
  State<AddCropPage> createState()=>_AddCropPageState();
}
class _AddCropPageState extends State<AddCropPage> {
  final formKey=GlobalKey<FormState>();
  final crop=TextEditingController();
  final keys=['acres','seeds','fertilizer','pesticides','labour','irrigation','machinery','other','yield','price'];
  late final Map<String,TextEditingController> c={for(final k in keys) k:TextEditingController(text:['seeds','fertilizer','pesticides','labour','irrigation','machinery','other'].contains(k)?'0':'')};
  String season='Kharif';
  double n(String k)=>double.tryParse(c[k]!.text.trim())??0;
  double get cost=>['seeds','fertilizer','pesticides','labour','irrigation','machinery','other'].fold(0,(s,k)=>s+n(k));
  double get revenue=>n('yield')*n('price');
  @override
  void dispose(){crop.dispose();for(final x in c.values){x.dispose();}super.dispose();}
  String? validate(String? v,{bool positive=false}) {
    if(v==null||v.trim().isEmpty)return 'Required';
    final x=double.tryParse(v.trim());
    if(x==null||!x.isFinite||x<0||(positive&&x==0))return positive?'Enter a number above zero':'Enter a valid number (0 or more)';
    return null;
  }
  Widget numberField(String key,String label,{bool positive=false})=>TextFormField(
    controller:c[key],keyboardType:const TextInputType.numberWithOptions(decimal:true),
    decoration:InputDecoration(labelText:label),validator:(v)=>validate(v,positive:positive),
    onChanged:(_)=>setState((){}));
  Widget section(String title,IconData icon,List<Widget> children)=>Container(
    margin:const EdgeInsets.only(bottom:16),padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),
      border:Border.all(color:const Color(0xFFE5EBE5))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(icon,color:farmGreen),const SizedBox(width:8),
        Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16))]),
      const SizedBox(height:14),...children]));
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Add crop record')),
    body:Form(key:formKey,child:ListView(padding:const EdgeInsets.all(16),children:[
      section('Crop details',Icons.grass,[
        TextFormField(controller:crop,textCapitalization:TextCapitalization.words,
          decoration:const InputDecoration(labelText:'Crop name',hintText:'Paddy, cotton, maize'),
          validator:(v)=>v==null||v.trim().isEmpty?'Enter crop name':null),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(value:season,decoration:const InputDecoration(labelText:'Growing season'),
          items:['Kharif','Rabi','Zaid','Year-round','Other'].map((s)=>DropdownMenuItem(value:s,child:Text(s))).toList(),
          onChanged:(v)=>setState(()=>season=v??season)),
        const SizedBox(height:12),numberField('acres','Land area (acres)',positive:true)]),
      section('Expense breakdown (₹)',Icons.account_balance_wallet_outlined,[
        numberField('seeds','Seeds cost'),const SizedBox(height:10),
        numberField('fertilizer','Fertilizer cost'),const SizedBox(height:10),
        numberField('pesticides','Pesticides cost'),const SizedBox(height:10),
        numberField('labour','Labour cost'),const SizedBox(height:10),
        numberField('irrigation','Irrigation / water cost'),const SizedBox(height:10),
        numberField('machinery','Machinery / equipment cost'),const SizedBox(height:10),
        numberField('other','Other costs'),const SizedBox(height:14),
        Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:paleGreen,borderRadius:BorderRadius.circular(14)),
          child:Row(children:[const Expanded(child:Text('Total expenses',style:TextStyle(fontWeight:FontWeight.bold))),
            Text(rupees(cost),style:const TextStyle(color:farmGreen,fontWeight:FontWeight.bold,fontSize:17))]))]),
      section('Expected harvest & income',Icons.trending_up,[
        numberField('yield','Expected yield (quintals)',positive:true),const SizedBox(height:10),
        numberField('price','Selling price per quintal (₹)',positive:true),const SizedBox(height:14),
        Text('Expected income: ${rupees(revenue)}',style:const TextStyle(fontWeight:FontWeight.bold,color:farmGreen,fontSize:16)),
        const SizedBox(height:6),Text('${revenue>=cost?'Estimated profit':'Estimated loss'}: ${rupees((revenue-cost).abs())}',
          style:TextStyle(fontWeight:FontWeight.bold,color:revenue>=cost?farmGreen:Colors.red,fontSize:16))]),
      FilledButton.icon(onPressed:save,icon:const Icon(Icons.save_outlined),
        label:const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text('Save crop record')),
        style:FilledButton.styleFrom(backgroundColor:farmGreen,minimumSize:const Size.fromHeight(52))),
      const SizedBox(height:24)
    ])));
  void save(){
    if(!formKey.currentState!.validate())return;
    Navigator.pop(context,CropRecord(id:DateTime.now().microsecondsSinceEpoch.toString(),
      crop:crop.text.trim(),season:season,acres:n('acres'),seeds:n('seeds'),fertilizer:n('fertilizer'),
      pesticides:n('pesticides'),labour:n('labour'),irrigation:n('irrigation'),machinery:n('machinery'),
      other:n('other'),yieldQ:n('yield'),price:n('price'),date:DateTime.now()));
  }
}
