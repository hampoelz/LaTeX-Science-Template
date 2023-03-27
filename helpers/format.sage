if not 'sage' in globals():
    from sage.all import *

from sage.structure.element import is_Vector, is_Matrix
from sage.libs.pari.convert_sage import gen_to_sage


def format_object(x, n=None):
    # convert input to sage object
    if not type(x).__module__.startswith('sage'):
        x = gen_to_sage(pari(f'{x}'))

    # convert number to decimal or scientific format based on complexity
    def general_format(x): return '{:g}'.format(float(x))

    # execute sage's "numerical_approx" function if the number contains decimals, otherwise return an integer
    def numerical_approx(x, digits=None):
        if n == 0:
            return Integer(f"{float(x):.0f}")
        x = x.n(digits=digits)
        value = general_format(x)
        if not n and not '.' in value:
            return Integer(value)
        return x

    # calculate digits of a number to the right and left of the decimal point
    def get_lengths(x):
        value = general_format(x)
        value = value.replace('-', '') # remove minus sign to get correct length of number
        if 'e' in value:
            value = value.split('e')[0]
        # 1 = default number of decimal places
        length = [len(value), n if n is not None and n >= 0 else 1]
        if '.' in value:
            value = value.split('.')
            r_len = 0 if value[0] == '0' else len(value[0])
            # Use custom 'n' decimals if defined
            l_len = n if n is not None and n >= 0 else len(value[1])
            length = [r_len, l_len]
        return length

    # calculate digits of a complex number or a number
    def get_digits(x):
        if hasattr(x, 'real') and hasattr(x, 'imag') and x.imag():
            # The real and imaginary parts of a complex number have the same number of decimal places,
            # so that no decimals are truncated later, the part with the most digits is used
            len_real = get_lengths(x.real())
            len_imag = get_lengths(x.imag())
            return max(len_real[0], len_imag[0]) + max(len_real[1], len_imag[1])
        return sum(get_lengths(x))

    # format a number for better readability
    def format_number(x, digits=None):
        if not digits:
            digits = get_digits(x)

        # handle complex numbers
        if hasattr(x, 'real') and hasattr(x, 'imag') and x.imag():
            x_real = numerical_approx(x.real(), digits=digits)
            x_imag = numerical_approx(x.imag(), digits=digits)

            # arrange real and imaginary parts
            v = vector([x_real, x_imag])
            R = v.base_ring()
            return R[['i']](v.list())

        return numerical_approx(x, digits=digits)

    # handle vectors
    if is_Vector(x):
        v, v_len = [], []
        # use the point with the most digits since each point will have the same number of decimal places in the vector
        for i in range(len(x)):
            v_len.append(get_digits(x[i]))
        # beautify every point of the vector and create a new vector
        for i in range(len(x)):
            v.append(format_number(x[i], digits=max(v_len)))
        return vector(v)

    # handle matrices
    if is_Matrix(x):
        m, m_len = [], []
        # use the point with the most digits since each point will have the same number of decimal places in the matrix
        for i in range(x.nrows()):
            for j in range(x.ncols()):
                m_len.append(get_digits(x[i][j]))
        # beautify every point of the matrix and create a new matrix
        for i in range(x.nrows()):
            m.append([])
            for j in range(x.ncols()):
                m[i].append(format_number(x[i][j], digits=max(m_len)))
        return matrix(m)

    # handle numbers
    return format_number(x)
