#!/usr/bin/env python3
"""
Script para gerar ícones do Android em todos os tamanhos necessários
Requer: pip install Pillow
"""

import os
from PIL import Image, ImageDraw
import io

def create_pdf_icon():
    """Cria um ícone de PDF com estilo semelhante ao da imagem fornecida"""
    
    # Definir tamanhos e diretórios
    sizes = {
        'mipmap-mdpi': 48,      # 1x
        'mipmap-hdpi': 72,      # 1.5x
        'mipmap-xhdpi': 96,     # 2x
        'mipmap-xxhdpi': 144,   # 3x
        'mipmap-xxxhdpi': 192,  # 4x
    }
    
    base_dir = 'android/app/src/main/res'
    
    for folder, size in sizes.items():
        # Criar imagem com fundo transparente
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Calcular dimensões
        padding = size // 8
        inner_size = size - (padding * 2)
        
        # Desenhar fundo branco arredondado
        margin = padding
        draw.rounded_rectangle(
            [(margin, margin), (size - margin, size - margin)],
            radius=size // 6,
            fill=(240, 240, 240),
            outline=(200, 200, 200),
            width=2
        )
        
        # Desenhar P de PDF (parte azul/escura)
        p_width = inner_size // 2
        p_height = inner_size
        p_left = padding + inner_size // 4
        p_top = padding
        
        # Letra P em azul escuro
        draw.rectangle(
            [(p_left, p_top), (p_left + p_width, p_top + p_height)],
            fill=(25, 55, 109)  # Azul escuro
        )
        
        # Parte branca do P
        draw.rectangle(
            [(p_left + 8, p_top + 8), (p_left + p_width - 8, p_top + p_height - 8)],
            fill=(240, 240, 240)
        )
        
        # Desenhar "DF" ou "PDF" pequeno
        df_start = p_left + p_width + 10
        df_y = p_top + inner_size // 3
        draw.rectangle(
            [(df_start, df_y), (df_start + 15, df_y + 30)],
            fill=(200, 200, 200)
        )
        
        # Salvar em todos os diretórios
        output_path = os.path.join(base_dir, folder, 'ic_launcher.png')
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        img.save(output_path, 'PNG')
        print(f'✓ Criado: {output_path}')

if __name__ == '__main__':
    try:
        create_pdf_icon()
        print('\n✅ Ícones criados com sucesso!')
    except Exception as e:
        print(f'❌ Erro: {e}')
        print('Instale Pillow com: pip install Pillow')
