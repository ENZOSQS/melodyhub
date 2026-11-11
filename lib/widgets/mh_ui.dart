import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Componentes visuais compartilhados do Melody Hub, seguindo os mockups em
/// `docs/mockups/`. Ficam aqui para que todas as telas usem o mesmo cabeçalho,
/// cartões, ícones e chips.

/// Logotipo: nota musical dourada, nome do app e o traço rosado embaixo.
class MelodyHubLogo extends StatelessWidget {
  const MelodyHubLogo({super.key, this.vertical = false, this.scale = 1});

  /// `true` empilha ícone e nome (tela de login); `false` coloca lado a lado.
  final bool vertical;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final nome = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: vertical
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Melody Hub',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
            height: 1.05,
          ),
        ),
        SizedBox(
          width: 92 * scale,
          height: 9 * scale,
          child: const CustomPaint(painter: _TracoPainter()),
        ),
      ],
    );
    final icone = Icon(
      Icons.music_note_rounded,
      color: AppColors.primary,
      size: 34 * scale,
    );
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [icone, SizedBox(height: 6 * scale), nome],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [icone, SizedBox(width: 6 * scale), nome],
    );
  }
}

class _TracoPainter extends CustomPainter {
  const _TracoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final caminho = Path()
      ..moveTo(size.width * .12, size.height * .85)
      ..quadraticBezierTo(
        size.width * .55,
        size.height * .15,
        size.width,
        size.height * .2,
      );
    canvas.drawPath(
      caminho,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = size.height * .32,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cabeçalho das telas principais: logotipo à esquerda e sino à direita.
/// O sino abre a configuração de lembretes de estudo.
class MelodyHeader extends StatelessWidget {
  const MelodyHeader({super.key, this.onNotificacoes});

  final VoidCallback? onNotificacoes;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
    child: Row(
      children: [
        // Quando a tela foi aberta por cima de outra, mostra a seta de voltar.
        if (Navigator.of(context).canPop()) ...[
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          ),
          const SizedBox(width: 4),
        ],
        const MelodyHubLogo(),
        const Spacer(),
        if (onNotificacoes != null)
          IconButton(
            tooltip: 'Lembretes de estudo',
            onPressed: onNotificacoes,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.text,
              size: 28,
            ),
          ),
      ],
    ),
  );
}

/// Título grande de página ("Aprender", "Relatório da semana", "Perfil").
class MhPageTitle extends StatelessWidget {
  const MhPageTitle(this.texto, {super.key, this.subtitulo});

  final String texto;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texto,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitulo!,
            style: const TextStyle(color: AppColors.muted, fontSize: 15),
          ),
        ],
      ],
    ),
  );
}

/// Título de seção ("Exercícios", "O que mais precisa de revisão").
class MhSectionTitle extends StatelessWidget {
  const MhSectionTitle(this.texto, {super.key, this.trailing});

  final String texto;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

/// Cartão com fundo de superfície, borda suave e cantos arredondados.
class MhCard extends StatelessWidget {
  const MhCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.destaque = false,
    this.corBorda,
    this.corFundo,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Fundo um pouco mais claro, usado em cartões de ação ("Abrir simulador").
  final bool destaque;
  final Color? corBorda;
  final Color? corFundo;

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(22);
    return Material(
      color:
          corFundo ?? (destaque ? AppColors.surfaceRaised : AppColors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: raio,
        side: BorderSide(color: corBorda ?? AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: raio,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Quadrado arredondado com um ícone, usado à esquerda dos cartões.
class MhIconTile extends StatelessWidget {
  const MhIconTile({
    super.key,
    required this.icone,
    this.cor = AppColors.primary,
    this.tamanho = 58,
    this.fundo,
  });

  final IconData icone;
  final Color cor;
  final double tamanho;
  final Color? fundo;

  @override
  Widget build(BuildContext context) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(
      color: fundo ?? cor.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(tamanho * .28),
    ),
    child: Icon(icone, color: cor, size: tamanho * .5),
  );
}

/// Linha vertical fina que separa o ícone do texto nos cartões.
class MhDividerVertical extends StatelessWidget {
  const MhDividerVertical({super.key, this.altura = 44});

  final double altura;

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: altura,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: AppColors.border,
  );
}

/// Selo pequeno com contorno rosado ("Teclado", "Violão").
class MhBadge extends StatelessWidget {
  const MhBadge({super.key, required this.texto, this.icone});

  final String texto;
  final IconData? icone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.secondary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.secondary.withValues(alpha: .8)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icone != null) ...[
          Icon(icone, size: 15, color: AppColors.text),
          const SizedBox(width: 6),
        ],
        Text(
          texto,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// Chip de seleção em formato de pílula: dourado quando selecionado.
class MhChoiceChip extends StatelessWidget {
  const MhChoiceChip({
    super.key,
    required this.texto,
    required this.selecionado,
    required this.onTap,
    this.icone,
  });

  final String texto;
  final bool selecionado;
  final VoidCallback onTap;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final corTexto = selecionado ? AppColors.background : AppColors.text;
    return Semantics(
      selected: selecionado,
      button: true,
      child: Material(
        color: selecionado ? AppColors.primary : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selecionado ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 18, color: corTexto),
                  const SizedBox(width: 8),
                ],
                Text(
                  texto,
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 15,
                    fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão de número com ícone no topo ("Precisão 78%").
class MhStatCard extends StatelessWidget {
  const MhStatCard({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.corIcone = AppColors.secondary,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final Color corIcone;

  @override
  Widget build(BuildContext context) => MhCard(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    child: Column(
      children: [
        Icon(icone, color: corIcone, size: 28),
        const SizedBox(height: 8),
        Text(
          rotulo,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.text, fontSize: 13),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            valor,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Barra de progresso em segmentos (etapas de uma rodada).
class MhSegmentedProgress extends StatelessWidget {
  const MhSegmentedProgress({
    super.key,
    required this.total,
    required this.concluidos,
  });

  final int total;
  final int concluidos;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < total; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 9,
            decoration: BoxDecoration(
              color: i < concluidos
                  ? AppColors.primary
                  : AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Cartão de retorno após a resposta: verde no acerto, coral no erro.
class MhFeedbackCard extends StatelessWidget {
  const MhFeedbackCard({
    super.key,
    required this.acertou,
    required this.titulo,
    this.detalhe,
  });

  static const verde = Color(0xFF8FD99A);
  static const coral = Color(0xFFFF7D91);

  final bool acertou;
  final String titulo;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    final cor = acertou ? verde : coral;
    return MhCard(
      corFundo: cor.withValues(alpha: .1),
      corBorda: cor.withValues(alpha: .45),
      child: Row(
        children: [
          Icon(
            acertou
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: cor,
            size: 38,
          ),
          MhDividerVertical(altura: detalhe == null ? 30 : 46),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: cor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (detalhe != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detalhe!,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
