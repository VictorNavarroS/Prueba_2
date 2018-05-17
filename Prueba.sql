create database prueba1;
use prueba1;

create table usuarios(
id_usuario int identity(1,1) primary key,
nombre varchar(50) not null,
apellidos varchar(50) not null,
mail varchar(150) not null unique,
clave varchar(50),
estado bit
);

create table permisos(
id_permiso int identity(1,1) primary key,
nombre varchar(50) not null,
estado bit
);

create table permisos_usuarios(
id_usuario int foreign key references usuarios (id_usuario),
id_permiso int foreign key references permisos (id_permiso)
);

create table logueos(
id_logueo int identity(1,1) primary key,
id_usuario int foreign key references usuarios (id_usuario),
fecha datetime
);


insert into usuarios values('Juan','Gonzalez', 'juan.gonzalez@aiep.cl','abc123',1);
insert into usuarios values('Maria','Diaz', 'maria.diaz@aiep.cl','abcde',1);
insert into usuarios values('Raul','Rodriguez', 'raul.rodriguez@aiep.cl','ac13',1);
insert into usuarios values('Miguel','Martinez', 'miguel.martinez@aiep.cl','654321a',1);
insert into usuarios values('Ana','Brito', 'ana.brito@aiep.cl','2323ad',1);
insert into usuarios values('Constanza','Pizarro', 'constanza.pizarro@aiep.cl','unodos',1);
insert into usuarios values('Javiera','Nieto', 'javiera.nieto@aiep.cl','martes',1);
insert into usuarios values('Tomas','Gonzalez', 'tomas.gonzalez@aiep.cl','adminadmin',1);


insert into permisos values ('mantenedor empresas',1);
insert into permisos values ('mantenedor usuario',1);
insert into permisos values ('informe usuario',1);
insert into permisos values ('informe empresas',1);
insert into permisos values ('exportables usuario',1);
insert into permisos values ('exportables empresa',1);
insert into permisos values ('envio correo masivo',1);


insert into permisos_usuarios values(1,1);
insert into permisos_usuarios values(1,2);
insert into permisos_usuarios values(1,3);
insert into permisos_usuarios values(1,4);
insert into permisos_usuarios values(1,5);
insert into permisos_usuarios values(1,6);
insert into permisos_usuarios values(1,7);
insert into permisos_usuarios values(2,1);
insert into permisos_usuarios values(2,3);
insert into permisos_usuarios values(2,5);
insert into permisos_usuarios values(3,2);
insert into permisos_usuarios values(3,4);
insert into permisos_usuarios values(3,6);
insert into permisos_usuarios values(4,7);
insert into permisos_usuarios values(5,5);
insert into permisos_usuarios values(5,6);
insert into permisos_usuarios values(5,7);



set dateformat dmy;
insert into logueos values(1,'07/04/2017');
insert into logueos values(2,'07/04/2016');
insert into logueos values(3,'05/04/2016');
insert into logueos values(4,'13/01/2017');
insert into logueos values(5,'15/02/2017');
insert into logueos values(6,'25/12/2016');
insert into logueos values(7,'30/01/2017');



--1)-----------------------------------------------------------------------------------------------------------------

create procedure permisos_asociados
@id int
as
begin
	select p.nombre from  permisos_usuarios u inner join permisos p on(u.id_permiso=p.id_permiso)where @id = id_usuario; 
end;


exec permisos_asociados 4;

--2)-----------------------------------------------------------------------------------------------------------------

create function logueo_permnitido(@correo varchar(150),@clave varchar (50))
returns bit
as
begin
	declare @bit int;
	if exists (select * from usuarios where estado=1 and @correo= mail and @clave=clave)
		begin
		set @bit=1;
		end;
	else
		begin
		set @bit=0;
		end;
	return @bit;
end;


select dbo.logueo_permnitido('tomas.gonzalez@aiep.cl','adminadmin');

--3)-----------------------------------------------------------------------------------------------------------------

create procedure desactiva_usuarios
as
begin
	declare @mayor int;
	declare @i int;	
	declare @tiempo int;
	select @mayor = max (id_logueo) from logueos;
	select @i = 1;
	while @i <= @mayor
	begin
		if exists (select * from logueos where id_usuario = @i)
		begin
			select @tiempo = DATEDIFF(mm,fecha,getdate())from logueos where id_usuario = @i;
			if @tiempo > 1
				begin
					update usuarios set estado=0 where id_usuario= @i ;
				end;
		end;
	set @i = @i + 1;
	end;
	end;
	
exec desactiva_usuarios;

--4)-----------------------------------------------------------------------------------------------------------------

create function cant_usuarios(@id_permiso int)
returns int
as
begin
	declare @cantidad int;
		select @cantidad= count (*) from permisos_usuarios where id_permiso= @id_permiso;
	return @cantidad;
end;

select dbo.cant_usuarios (7);

--5)-----------------------------------------------------------------------------------------------------------------

create procedure texto_compatible
@texto varchar(50)
as
begin
	select * from usuarios where nombre like '%'+@texto+'%' or apellidos like '%'+@texto+'%';			
end;
	
exec texto_compatible 'to';

--6)-----------------------------------------------------------------------------------------------------------------

create function nunca_logueado()
returns int
as
begin
	declare @cantidad bit;
	declare @n1 int;
	declare @n2 int;
	select @n1= count(*) from usuarios;
	select @n2 =count(*) from logueos;
	set @cantidad = @n1 - @n2
	return @cantidad;
end;

select dbo.nunca_logueado();

/*
6) Usando la tabla usuarios (1ra prueba) Cree un trigger q impida insertar si :
	- la clave posee menos de 5 caracteres
	- el mail no posee @
	debera enviar mensaje para cada problema
*/

create trigger ejercicio6
on usuarios
instead of insert
as
begin	
	declare @mail varchar (150);
	declare	@clave varchar (50);	
	select @mail = i.mail from inserted i;
	select @clave = i.clave from inserted i;	
	if LEN(@clave)>5 and @mail like '%@%'
		begin
			insert into usuarios(nombre,apellidos,mail,clave,estado) select * from inserted;
		end;
	else 
		begin
			if LEN(@clave)<5
				begin
					print 'ingrese una clave de 5 o mas caracteres';
				end;
			else 
				begin
				if @mail not like '%@%'			
				print 'Ingrese un mail valido';
				end;
		end;
end;
drop trigger ejercicio6

insert into usuarios values('vict','navar', 'vitok@aiep.cl','987654',1);

/*
7) por temas de seguridad ningun usuario debera poseer mas de tres permisos, 
impida que se inserten registros en la tabla permisos_usuarios si el usuario ya posee la cuota
*/

create trigger ejercicio7
on permisos_usuarios
instead of insert 
as
begin
	declare @id_usuario int;
	declare @id_permiso int;
	declare @permisos int;
	select @id_usuario = i.id_usuario from inserted i;
	select @id_permiso = i.id_permiso from inserted i;
	select @permisos = COUNT(id_permiso) from permisos_usuarios where id_usuario= @id_usuario;
	if @permisos >3
		begin
			print 'Este usuario ya posee tres o mas permisos'
		end;
	else 
		begin
			insert into permisos_usuarios values(@id_usuario,@id_permiso);
		end;
end;

insert into permisos_usuarios values(1,1);
/*
8)Debe impedir que se inserten datos con fecha superior al dia de hoy en la tabla logueos
*/
create trigger ejercicio8
on logueos
instead of insert
as
begin
	set dateformat dmy;
	declare @id int;
	declare @fecha date;
	select @id = i.id_usuario from inserted i;
	select @fecha = i.fecha from inserted i;
	if @fecha > GETDATE()
		begin
			print 'Ingrese una fecha actualizada';
		end;
	else
		begin			
			insert into logueos values(@id,@fecha);
		end;
end;

insert into logueos values(1,'07/04/2017');
/*
9) Por medidas de seguridad debera impedir que se eliminen registros en la tabla logueos
*/

create trigger ejercicio9
on logueos
instead of delete
as
begin
	print 'No puede eliminar datos de esta tabla'
end;

delete from logueos where id_logueo=2
/*
10) El campo mail, de la tabla usuarios, se usa para realizar el logueo del usuario; por lo cual, debera impedir
que se modifique este dato
*/

create trigger ejercicio10
on usuarios
instead of update
as
begin
	declare @mail varchar (150);
	declare @mail2 varchar (150);
	select @mail = i.mail from inserted i;
	select @mail2 = d.mail from deleted d;
	if @mail != @mail2
			begin
				print 'No puede modificar este dato'
			end;
end;
drop trigger ejercicio10

update usuarios set mail = 'adssadasd@sad.com' where id_usuario =1;


/*EJERCICIOS clase 29/04/17

1) por regla de negocio luego de crear un usuario,debera darle permiso para el "mantenedor de usuarios"*/

create trigger ejer1
on usuarios
for insert
as
begin
	declare @id int;
	select @id = i.id_usuario from inserted i;
	begin
		insert into permisos_usuarios values(@id,2); 
	end;
end;

/*
2) en la tabla logueos, si se intenta insertar un registro con un id_usuario ya existente en la tabla,
se debera modificar la informacion existente. solo en caso de no existir el id_usuario, se insertara
*/

create trigger ejer2
on logueos 
instead of insert
as
begin
	declare @id int;
	select @id= i.id_usuario from inserted i;
	if exists (select id_usuario from logueos where id_usuario = @id)
		begin
			update logueos set fecha = GETDATE() where id_usuario =@id;
		end;
	else
		begin		
			insert into logueos values(@id,GETDATE());
		end;
end;

set dateformat dmy;
insert into logueos(id_usuario,fecha) values(8,GETDATE());

/*
3) cree un desencadenador q luego de desactivar un usuario (pasar estado a cero)
elimine todos los registros asociados a este usaurio en la tabla "permisos_usuarios"
*/

create trigger ejer3
on usuarios 
for update
as
begin
	declare @id int;
	declare @estado bit;
	select @id = i.id_usuario from inserted i;
	select @estado = i.estado from inserted i;
	if @estado=0
		begin
			delete from permisos_usuarios where id_usuario = @id;
		end;
end;

update usuarios set estado = 0 where id_usuario=6;


backup database prueba1
to disk = 'D:\respaldo\uno.sql'
with init;