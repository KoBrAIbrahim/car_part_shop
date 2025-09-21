// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 1;

  @override
  CartItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItem(
      partNumber: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      price: fields[3] as double,
      imageUrl: fields[4] as String?,
      brand: fields[5] as String,
      category: fields[6] as String,
      quantity: fields[7] as int,
      carMake: fields[8] as String,
      carModel: fields[9] as String?,
      carYear: fields[10] as String?,
      addedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.partNumber)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.brand)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.quantity)
      ..writeByte(8)
      ..write(obj.carMake)
      ..writeByte(9)
      ..write(obj.carModel)
      ..writeByte(10)
      ..write(obj.carYear)
      ..writeByte(11)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
