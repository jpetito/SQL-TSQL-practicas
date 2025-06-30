
/*2. la Actualmente el campo fact_vendedor representa al empleado que vendió
la factura. Implementar el/los objetos necesarios para respetar
integridad referenciales de dicho campo suponiendo que no existe una
foreign key entre ambos.

NOTA: No se puede usar una foreign key para el ejercicio, deberá buscar
otro método */

create trigger integridadVendedor on Factura after insert, update
as
begin
    if exists (
        select fact_vendedor
        from inserted i
        where not exists (
            select empl_codigo
            from Empleado
            where empl_codigo = i.fact_vendedor
        )
    )
    begin
        rollback
        raiserror('El vendedor asignado no existe en la tabla Empleado.', 16, 1)
    end
end
go
