using System.Text.Json.Serialization;

namespace SistemaGestionDocumental.DTOs;

public class MovimientoDTO
{
    public int Id { get; set; }
    public int DocumentoId { get; set; }
    public string? DocumentoCodigo { get; set; }
    public string TipoMovimiento { get; set; } = string.Empty;
    public int? AreaOrigenId { get; set; }
    public string? AreaOrigenNombre { get; set; }
    public int? AreaDestinoId { get; set; }
    public string? AreaDestinoNombre { get; set; }
    /// <summary>Usuario responsable del movimiento (ej. a quién se prestó).</summary>
    public int? UsuarioId { get; set; }
    /// <summary>Nombre del usuario responsable del movimiento.</summary>
    public string? UsuarioNombre { get; set; }
    /// <summary>Usuario autenticado que registró la acción.</summary>
    public int? UsuarioRegistroId { get; set; }
    /// <summary>Nombre del usuario que registró la acción.</summary>
    public string? UsuarioRegistroNombre { get; set; }
    public string? Observaciones { get; set; }
    public DateTime FechaMovimiento { get; set; }
    public DateTime? FechaDevolucion { get; set; }
    /// <summary>Fecha límite de devolución del préstamo.</summary>
    public DateTime? FechaLimiteDevolucion { get; set; }
    public string Estado { get; set; } = string.Empty;
}

public class CreateMovimientoDTO
{
    public int DocumentoId { get; set; }
    public string TipoMovimiento { get; set; } = string.Empty; // Entrada, Salida, Derivacion
    public int? AreaOrigenId { get; set; }
    public int? AreaDestinoId { get; set; }
    public int? UsuarioId { get; set; }
    public int? UsuarioRegistroId { get; set; }
    public string? Observaciones { get; set; }
    /// <summary>Fecha límite de devolución del préstamo (obligatoria para Salida).</summary>
    public DateTime? FechaLimiteDevolucion { get; set; }
}

public class DevolverDocumentoDTO
{
    [JsonPropertyName("movimientoId")]
    public int MovimientoId { get; set; }
    [JsonPropertyName("observaciones")]
    public string? Observaciones { get; set; }

    [JsonPropertyName("usuarioRegistroId")]
    public int? UsuarioRegistroId { get; set; }
}

