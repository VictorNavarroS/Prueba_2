create database prueba;
use prueba;

create table automoviles(
patente varchar(6) primary key,
marca varchar(15),
modelo varchar(15),
precio int,
año int,
es_nuevo bit
);

create table ofertas(
patente varchar(6) foreign key references automoviles(patente),
precio_antiguo int,
precio_nuevo int
);

create table errores(
nro_error int identity (1,1) primary key,
fecha datetime,
descripcion varchar(150)
);

insert into automoviles values('sw1977','kia','rio',5000000,2013,1);
insert into automoviles values('sw1982','mazda','3',7000000,2013,1);
insert into automoviles values('sw1987','chevrolet','corvette',10000000,2013,1);

/*EJERCICIO 1*/
create trigger ejercicio1
on automoviles
for update
as
begin
	declare @precio1 int;
	declare @precio2 int;
	declare @patente varchar(6);
	select @precio1 = d.precio from deleted d;
	select @precio2 = i.precio from inserted i;
	select @patente = i.patente from inserted i;
	if @precio2 < @precio1
		begin
			insert into ofertas values (@patente,@precio1,@precio2); 
		end;
end;

update automoviles set precio= 4000000 where patente = 'sw1977';

/*EJERCICIO 2*/
alter trigger ejercicio2
on automoviles 
instead of insert
as
begin
	declare @precio int;
	declare @fecha varchar(15);
	declare @añoauto datetime;
	declare @año int;
	declare @patente varchar(6);
	select @patente = i.patente from inserted i;
	select @precio = i.precio from inserted i;
	select @año = i.año from inserted i;
	set @fecha =concat('01-01-', @año);
	set @añoauto=cast(@fecha as datetime);
	if @precio < 100000 or @fecha > getdate() or  len(@patente) != 6 
		begin
			if @precio < 100000 
				begin
					insert into errores values (GETDATE(),'El Precio insertado es muy bajo');
				end;
			if @fecha > getdate()
				begin
					insert into errores values (GETDATE(),'Año de vehiculo mal ingresado');
				end;
			if len(@patente) != 6 
				begin
					insert into errores values (GETDATE(),'Largo de patente es distinto de 6 caracteres');
				end;
		end;
	else 
		begin
			insert into automoviles select * from inserted;
		end;
		
end;

insert into automoviles (patente,marca,modelo,precio,año,es_nuevo) values('sw6969','nissan','terrano',8000000,2020,0);


/*EJERCICIO 3*/
create trigger ejercicio3
on automoviles
instead of delete
as
begin
	declare @patente varchar(6);
	select @patente = d.patente from deleted d;
	if exists (select * from ofertas where patente= @patente)
		begin
			delete from ofertas where patente = @patente;		
		end;
	delete from automoviles where patente = @patente;
end;

delete from automoviles where patente='sw6969';

